# == DESCRIPTION
# An expression database.
# = OVERVIEW
# When in doubt, you can always use ´.inspect´ on any object to get a full ist of 
# available attributes
# = USAGE
#	require 'expression-database'
# 	ExpressionDB::DBConnection.connect("mammal_expression") // Connects to the database (here: mammal_expression)
# 	dataset = ExpressionDB::Dataset.find(:first) // Retrieves the first dataset from the DB (usually the only one)
# 	dataset.samples.each do |sample|
# 		puts sample.name
# 	end
# // list all samples belonging to the dataset
#
#	human = ExpressionDB::GenomeDb.find_by_name('homo_sapiens')
#  	human.genes.each do |gene|
#		puts gene.stable_id
#		gene.xref_samples.each do |x|
#			puts "\t#{x.sample.name} #{x.fpkm}"
#		end
#	end
# // Go over all annotated genes and list expression values across all samples 
#
#	gene = ExpressionDB::Gene.find_by_stable_id('ENSG00000121101')
#	gene.xref_samples.each do |xref|
#		puts "{xref.sample.name} #{x.fpkm}"
#	end
# // List all expression values for a given Ensembl gene


module ExpressionDB

	# = DESCRIPTION
	# GenomeDb is the table that holds information
	# on the various genomes. Genomes have both ensembl_genes
	# as well as cufflinks_genes (see below)
	class GenomeDb < DBConnection
		self.primary_key = "genome_db_id"
		has_many :genes
		has_many :cufflinks_genes
	end
	
	# = DESCRIPTION
	# A dataset refers to a particular experiment
	# the expression data was taken from. Datasets have samples, which
	# are connected to ensembl_genes and cufflinks_genes with FPKM values
	class Dataset < DBConnection
		self.primary_key = 'dataset_id'
		has_many :samples
		has_many :cufflinks_genes
	end

	# = DESCRIPTION
	# The source of the gene annotation - can be 
	# ensembl, rum, none
	class Annotation < DBConnection
		self.primary_key = 'annotation_id'
		has_many :genes
		has_many :cufflinks_genes

	end
	
	# = DESCRIPTION
	# A sample refers to a particular tissue, from which reads 
	# were measured. Samples belong to datasets and are
	# connected to genes and transcripts through
	# xref_samples.
	class Sample < DBConnection
		self.primary_key = 'sample_id'
		belongs_to :dataset, :foreign_key => "dataset_id"
		has_many :xref_samples
	end
		
	# = DESCRIPTION
	# A table holding information on annotated
	# genes. Genes belong to genome_dbs and are connect to samples
	# through xref_samples.
	# = USAGE
	#	gene = ExpressionDB::Gene.find_by_stable_id('ENSG00000121101')
	#	gene.xref_samples.each do |xref|
	#		puts "#{x.sample.name} #{x.fpkm}"
	#	end
	class Gene < DBConnection
		self.primary_key = 'gene_id'
		belongs_to :genome_db, :foreign_key => "genome_db_id"
		belongs_to :annotation, :foreign_key => "annotation_id"
		has_many :xref_samples, :foreign_key => 'source_id', :conditions => "source_type = 'gene'", :order => 'sample_id ASC'
		has_many :xref_features, :foreign_key => 'source_id', :conditions => "source_type = 'gene'", :order => 'external_db_id ASC'
                has_many :align_features, :foreign_key => 'source_id', :conditions => "source_type = 'gene'"
		has_many :transcripts
		
		# = DESCRIPTION
		# Returns xrefs only for samples from a given dataset (ExpressionDB::Dataset object)
		def xrefs_by_dataset(dataset)
			return self.xref_samples.select{|x| x.sample.dataset == dataset }.sort_by{|x| x.sample.name}
		end
		
		# = DESCRIPTION
		# Returns xrefs only for specific samples (ExpressionDB::Sample object required)
		def xrefs_by_sample(sample)
			return self.xref_samples.select{|x| x.sample == sample}
		end

		# = DESCRIPTION
		# Collects all expression values for this gene within a given
		# dataset and calculate the expression entropy as:
		# S = -sum(Pi x ln(Pi)) with ...
		def entropy_by_dataset(dataset)
			xrefs = self.xrefs_by_dataset(dataset)			
			fpkms = xrefs.collect{|x| x.fpkm.to_f }
			t = 0.0 # the summ of all expressions
			fpkms.each {|f| t+= f }
			p = [] # the values for each tissue as fraction of the total
			xrefs.each do |xref|
				e = xref.fpkm/t	
							
				e > 0.0 ? p << e*Math.log(e) : p << 0.0
			end
			answer = 0.0
			p.each  {|element| answer += element }
			return answer*(-1)	
		end
		
	end

	# = DESCRIPTION
	# A table holding information on EnsEMBL
	# transcripts. Transcripts belong to ensembl_genes and
	# are connected to samples through xref_samples
	class Transcript < DBConnection
		self.primary_key = 'transcript_id'
		has_many :xref_samples, :foreign_key => 'source_id', :conditions => "source_type = 'transcript'", :order => 'sample_id ASC'
		has_many :xref_features, :foreign_key => 'source_id', :conditions => "source_type = 'transcript'", :order => 'external_db_id ASC'
                has_many :align_features, :foreign_key => 'source_id', :conditions => "source_type = 'transcript'"
		belongs_to :gene
		
		# = DESCRIPTION
		# Returns xrefs only for samples from a given dataset (ExpressionDB::Dataset object)
		def xrefs_by_dataset(dataset)
			return self.xref_samples.select{|x| x.sample.dataset == dataset }.sort_by{|x| x.sample.name}
		end
	
		# = DESCRIPTION
		# Returns xrefs only for specific samples (ExpressionDB::Sample object required)		
		def xrefs_by_sample(sample)
			return self.xref_samples.select{|x| x.sample == sample}
		end
		
	end

	
	# = DESCRIPTION
	# A table holding cufflinks-predicted gene models.
	# These models are *only* valid within the context of a given dataset.
	# They are connected to sample through xref_samples
	class CufflinksGene < DBConnection
		self.primary_key = 'cufflinks_gene_id'
		belongs_to :dataset, :foreign_key => 'dataset_id'
		belongs_to :genome_db, :foreign_key => 'genome_db_id'
		belongs_to :annotation, :foreign_key => 'annotation_id'
		has_many :cufflinks_transcripts
		has_many :xref_samples, :foreign_key => 'source_id', :conditions => "source_type = 'cufflinks_gene'", :order => 'sample_id ASC'
		has_many :xref_features, :foreign_key => 'source_id', :conditions => "source_type = 'cufflinks_gene'", :order => 'external_db_id ASC'
                has_many :align_features, :foreign_key => 'source_id', :conditions => "source_type = 'cufflinks_gene'"		

		# = DESCRIPTION
		# Returns xrefs only for samples from a given dataset (ExpressionDB::Dataset object)
		def xrefs_by_dataset(dataset)
			return self.xref_samples.select{|x| x.sample.dataset == dataset }.sort_by{|x| x.sample.name}
		end
		
		# = DESCRIPTION
		# Returns xrefs only for specific samples (ExpressionDB::Sample object required)		
		def xrefs_by_sample(sample)
			return self.xref_samples.select{|x| x.sample == sample}
		end

		# = DESCRIPTION
		# Collects all expression values for this gene within a given
		# dataset and calculate the expression entropy as:
		# S = -sum(Pi x ln(Pi)) with ...
		def entropy_by_dataset(dataset)
			xrefs = self.xrefs_by_dataset(dataset)			
			fpkms = xrefs.collect{|x| x.fpkm.to_f }
			t = 0.0 # the summ of all expressions
			fpkms.each {|f| t+= f }
			p = [] # the values for each tissue as fraction of the total
			xrefs.each do |xref|
				e = xref.fpkm/t	
							
				e > 0.0 ? p << e*Math.log(e) : p << 0.0
			end
			answer = 0.0
			p.each  {|element| answer += element }
			t = nil
			return answer*(-1)	
		end

	end
	
	# = DESCRIPTION
	# A table holding cufflinks-predicted transcript models.
	# Transcripts belong to context-dependend cufflinks_genes.
	# They are connected to sample through xref_samples 
	class CufflinksTranscript < DBConnection
		self.primary_key = 'cufflinks_transcript_id'
		belongs_to :cufflinks_gene
		has_many :xref_samples, :foreign_key => 'source_id', :conditions => "source_type = 'cufflinks_transcript'"
		has_many :xref_features, :foreign_key => 'source_id', :conditions => "source_type = 'cufflinks_transcript'", :order => 'external_db_id ASC'
                has_many :align_features, :foreign_key => 'source_id', :conditions => "source_type = 'cufflinks_transcript'"
		
		# = DESCRIPTION
		# Returns xrefs only for samples from a given dataset (ExpressionDB::Dataset object)
		def xrefs_by_dataset(dataset)
			return self.xref_samples.select{|x| x.sample.dataset == dataset }.sort_by{|x| x.sample.name}
		end
		
		# = DESCRIPTION
		# Returns xrefs only for specific samples (ExpressionDB::Sample object required)
		def xrefs_by_sample(sample)
			return self.xref_samples.select{|x| x.sample == sample}
		end
			
	end
	
	# = DESCRIPTION
	# Holds information on external databases
	# Allows association of mapped features for annotations
	class ExternalDb < DBConnection
		self.primary_key = 'external_db_id'
		has_many :xref_features
	end
	
	# = DESCRIPTION
	# Links the different annotation tables to the external_db table
	# Allows for mapping of aligned features (PFAM, BLAST, etc...)
	class XrefFeature < DBConnection

		self.primary_key = 'xref_feature_id'
		belongs_to :external_db, :foreign_key => 'external_db_id'
		belongs_to :gene, :class_name => "Gene", :foreign_key => 'source_id', :conditions => ["source_type = 'gene'"]
      		belongs_to :transcript, :class_name => "Transcript", :foreign_key => 'source_id', :conditions => ["source_type = 'transcript'"]
      		belongs_to :cufflinks_gene, :class_name => "CufflinksGene", :foreign_key => 'source_id', :conditions => ["source_type = 'cufflinks_gene'"]
      		belongs_to :cufflinks_transcript, :class_name => "CufflinksTranscript", :foreign_key => 'source_id', :conditions => ["source_type = 'cufflinks_transcript'"]
	end
	
	# = DESCRIPTION
	# Links aligned features to genes and transcripts (e.g. miRNA target predictions)
	class AlignFeature < DBConnection
		self.primary_key = 'align_feature_id'

		belongs_to :gene, :class_name => "Gene", :foreign_key => 'source_id', :conditions => ["source_type = 'gene'"]
                belongs_to :transcript, :class_name => "Transcript", :foreign_key => 'source_id', :conditions => ["source_type = 'transcript'"]
                belongs_to :cufflinks_gene, :class_name => "CufflinksGene", :foreign_key => 'source_id', :conditions => ["source_type = 'cufflinks_gene'"]
                belongs_to :cufflinks_transcript, :class_name => "CufflinksTranscript", :foreign_key => 'source_id', :conditions => ["source_type = 'cufflinks_transcript'"]

	end

	# = DESCRIPTION
	# Links the gene/transcript tables to samples. 
	# This table holds the expression data!
	# = IMPORTANT
	# This table links multiple tables to the sample table. Source tables are
	# specified via the source_type column. Do not insert data unless specifying
	# the *correct* source_type.
	class XrefSample < DBConnection
		
		self.primary_key = 'xref_id'
		belongs_to :sample, :foreign_key => 'sample_id'
	     	belongs_to :gene, :class_name => "Gene", :foreign_key => 'source_id', :conditions => ["source_type = 'gene'"]
      		belongs_to :transcript, :class_name => "Transcript", :foreign_key => 'source_id', :conditions => ["source_type = 'transcript'"]
      		belongs_to :cufflinks_gene, :class_name => "CufflinksGene", :foreign_key => 'source_id', :conditions => ["source_type = 'cufflinks_gene'"]
      		belongs_to :cufflinks_transcript, :class_name => "CufflinksTranscript", :foreign_key => 'source_id', :conditions => ["source_type = 'cufflinks_transcript'"]
	end

	# = DESCRIPTION
	# Coordinates for repeat elements.
	class Repeat < DBConnection
		self.primary_keys :chr_name, :chr_start, :chr_end

	end

	# = DESCRIPTION
	# Name of chromosomes and their length
	class SeqRegion < DBConnection
		self.primary_key = 'seq_region_id'
	end

end
