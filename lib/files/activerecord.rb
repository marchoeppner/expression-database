# = DESCRIPTION
# Maps out the tables in the DB

module ExpressionDB

	# = DESCRIPTION
	# GenomeDb is the table that holds information
	# on the various genomes. Genomes have both ensembl_genes
	# as well as cufflinks_genes (see below)
	class GenomeDb < DBConnection
		set_primary_key "genome_db_id"
		has_many :ensembl_genes
		has_many :cufflinks_genes
	end
	
	# = DESCRIPTION
	# A dataset refers to a particular experiment
	# the expression data was taken from. Datasets have samples, which
	# are connected to ensembl_genes and cufflinks_genes with FPKM values
	class Dataset < DBConnection
		set_primary_key 'dataset_id'
		has_many :samples
		has_many :cufflinks_genes
	end
	
	# = DESCRIPTION
	# A sample refers to a particular tissue, from which reads 
	# were measured. Samples belong to datasets and are
	# connected to ensembl_genes and cufflinks_genes through
	# xref_ensembl_genes_samples (or equivalent).
	class Sample < DBConnection
		set_primary_key 'sample_id'
		belongs_to :dataset, :foreign_key => "dataset_id"
		has_many :xref_gene_samples
		has_many :genes, :through => :xref_gene_samples
	end
	
	# = DESCRIPTION
	# A cross-reference to link EnsEMBL genes
	# to samples. This class holds measurements (fpkm)
	class XrefEnsemblGeneSample < DBConnection
		set_primary_keys :sample_id,:gene_id
		belongs_to :sample, :foreign_key => "sample_id"
		belongs_to :gene, :foreign_key => "gene_id"
	end
	
	# = DESCRIPTION
	# A table holding information on EnsEMBL
	# genes. Genes belong to genome_dbs and are connect to samples
	# through xref_ensembl_gene_samples.
	class EnsemblGene < DBConnection
		set_primary_key 'gene_id'
		belongs_to :genome_db, :foreign_key => "genome_db_id"
		has_many :xref_gene_samples
		has_many :samples, :through => :xref_gene_samples
	end

	# = DESCRIPTION
	# A table holding information on EnsEMBL
	# transcripts. Transcripts belong to ensembl_genes and
	# are connected to samples through xref_ensembl_transcript_samples
	class EnsemblTranscript < DBConnection
		set_primary_key 'transcript_id'
		has_many :xref_transcript_samples
		has_many :samples, :through => :xref_transcript_samples
		belongs_to :gene
	end
	
	# = DESCRIPTION
	# A cross-reference to link EnsEMBL transcripts
	# to samples. This class holds measurements (fpkm).
	class XrefEnsemblTranscriptSample < DBConnection
		set_primary_keys :transcript_id,:sample_id
		belongs_to :transcript, :foreign_key => "transcript_id"
		belongs_to :sample, :foreign_key => "sample_id"
	end
	
	# = DESCRIPTION
	# A table holding cufflinks-predicted gene models.
	# These models are *only* valid within the context of a given dataset.
	class CufflinksGene < DBConnection
		set_primary_key 'cufflinks_gene_id'
		belongs_to :dataset, :foreign_key => 'dataset_id'
		belongs_to :genome_db, :foreign_key => 'genome_db_id'
		has_many :cufflinks_transcripts
	end
	
	# = DESCRIPTION
	# A table holding cufflinks-predicted transcript models.
	# Transcripts belong to context-dependend cufflinks_genes. 
	class CufflinksTranscript < DBConnection
		set_primary_key 'cufflinks_transcript_id'
		belongs_to :cufflinks_gene
	end
	
end
