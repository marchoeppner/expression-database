# = DESCRIPTION
# Maps out the tables in the DB

module ExpressionDB
	
	class Dataset < DBConnection
		set_primary_key 'dataset_id'
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

end
