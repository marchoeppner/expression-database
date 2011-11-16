# = DESCRIPTION
# Maps out the tables in the DB

module ExpressionDB
	
	class Dataset < DBConnection
		set_primary_key 'dataset_id'
		has_many :samples
	end
	
	class Sample < DBConnection
		set_primary_key 'sample_id'
		belongs_to :dataset, :foreign_key => "dataset_id"
		has_many :xref_gene_samples
		has_many :genes, :through => :xref_gene_samples
	end
	
	class XrefGeneSample < DBConnection
		set_primary_keys :sample_id,:gene_id
		belongs_to :sample, :foreign_key => "sample_id"
		belongs_to :gene, :foreign_key => "gene_id"
	end
	
	class Gene < DBConnection
		set_primary_key 'gene_id'
		has_many :xref_gene_samples
		has_many :samples, :through => :xref_gene_samples
	end

	class Transcript < DBConnection
		set_primary_key 'transcript_id'
		has_many :xref_transcript_samples
		has_many :samples, :through => :xref_transcript_samples
		belongs_to :gene
	end
	
	class XrefTranscriptSample < DBConnection
		set_primary_keys :transcript_id,:sample_id
		belongs_to :transcript, :foreign_key => "transcript_id"
		belongs_to :sample, :foreign_key => "sample_id"
	end
	
end
