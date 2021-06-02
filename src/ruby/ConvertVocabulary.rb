require 'csv'
require 'set'

class Vocabulary

  attr_reader :iri, :extends, :with, :concepts

  def initialize(iri, prefix, with = '#')
    @iri = iri
    @prefix = prefix
    @with = with
    @extends = Set.new
    @concepts = Hash.new
  end

  def to_s
    lines = []
    lines << "vocabulary <#{@iri}> with #{@with} as #{@prefix} {\n"
    @extends.each { |u| lines << "    extends <#{u}>\n"}
    @concepts.each_value { |c| lines << c.to_s }
    lines << '}'
    lines.join("\n")
  end

end

class Concept

  attr_reader :label, :name, :types, :rest_all

  def initialize(label, types = Set.new)
    @label = label
    @name = label_to_name(label)
    @types = types.respond_to?(:each) ? types : Set.new([types])
    @rest_all = {}
  end

  def label_to_name(label)
    label.gsub(/\s+/, '')
  end

  def to_s
    lines = []
    lines << %(    @rdfs:label "#{@label}")
    lines << "    concept #{@name} :> #{@types.to_a.join(', ')} ["
    @rest_all.each do |prop, range|
      lines << "        restricts all relation #{prop} to #{range}"
    end
    lines << "    ]\n"
    lines.join("\n")
  end
end

vocab = Vocabulary.new(
  'http://incose.org/pwg/s-star/vocabulary/power-interface',
  'power-interface'
)
vocab.extends << 'http://www.w3.org/2000/01/rdf-schema'
vocab.extends << 'http://incose.org/pwg/s-star/vocabulary/interface'

table = CSV.new(ARGF, headers: true)

cs = vocab.concepts
table.each do |row|

  if (ia_cell = row['Configured Interaction Name'])
    ia_label = ia_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    cs.fetch(ia_label) { |k| cs[k] = Concept.new(ia_label, 'interface:FunctionalInteraction')}
  end

  if (role_cell = row['Configured Role Name'])
    role_label = role_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    sy_c = cs.fetch(role_label) { |k| cs[k] = Concept.new(role_label, 'interface:System')}
    provides_if_rest_label = "#{role_label} Provided Interface"
    provides_if_rest_c = cs.fetch(provides_if_rest_label) { |k| cs[k] = Concept.new(provides_if_rest_label, 'interface:Interface')}
    sy_c.rest_all['interface:providesInterface'] = provides_if_rest_c.name
    int_thr_port_rest_label = "#{role_label} Interacts Through Port"
    int_thr_port_rest_c = cs.fetch(int_thr_port_rest_label) { |k| cs[k] = Concept.new(int_thr_port_rest_label, 'interface:Port')}
    sy_c.rest_all['interface:interactsThrough'] = int_thr_port_rest_c.name
  end

  if (if_cell = row['Configured Interface Name'])
    if_label = if_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    if_c = cs.fetch(if_label) { |k| cs[k] = Concept.new(if_label, 'interface:Interface')}
    if_c.types << provides_if_rest_c.name
  end

  if (io_cell = row['Configured Input Output Name'])
    io_label = io_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    cs.fetch(io_label) { |k| cs[k] = Concept.new(io_label, 'interface:InputOutput')}
  end

  if (port_cell = row['Configured Port Name'])
    port_label = port_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    port_c = cs.fetch(port_label) { |k| cs[k] = Concept.new(port_label, 'interface:Port')}
    port_c.types << int_thr_port_rest_c.name
  end

  if (soa_cell = row['Configured SOA Name'])
    soa_label = soa_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    cs.fetch(soa_label) { |k| cs[k] = Concept.new(soa_label, 'interface:SystemOfAccess')}
  end

  if (ar_cell = row['Configured Arch Relat Name'])
    ar_label = ar_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    cs.fetch(ar_label) { |k| cs[k] = Concept.new(ar_label, 'interface:ArchitecturalRelationship')}
  end

  if (arr_cell = row['Configured Arch Relat Role Name'])
    arr_label = arr_cell.to_s.split('::').last.gsub(/ \[.*\z/, '')
    cs.fetch(arr_label) { |k| cs[k] = Concept.new(arr_label, 'interface:ArchitecturalRelationshipRole')}
  end

end

puts vocab.to_s
