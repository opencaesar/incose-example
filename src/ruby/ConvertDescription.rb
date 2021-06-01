require 'csv'
require 'set'

exchanges = {
  'In' => 'interface:receives',
  'Out' => 'interface:sends',
  'Bi' => 'interface:exchanges'
}

class Description

  attr_reader :iri, :extends, :with, :concept_instances, :uses

  def initialize(iri, prefix, with = '#')
    @iri = iri
    @prefix = prefix
    @with = with
    @uses = Set.new
    @concept_instances = Hash.new
  end

  def to_s
    lines = []
    lines << "description <#{@iri}> with #{@with} as #{@prefix} {\n"
    @uses.each { |u| lines << "    uses <#{u}>\n" }
    @concept_instances.values.each { |ci| lines << ci.to_s }
    lines << '}'
    lines.join("\n")
  end

end

class ConceptInstance

  attr_reader :label, :name, :types, :properties

  def initialize(label, types = Set.new)
    @label = label
    @name = label_to_name(label)
    @types = types.respond_to?(:each) ? types : Set.new([types])
    @properties = Hash.new { |h, k| h[k] = Set.new }
  end

  def label_to_name(label)
    label.downcase.gsub(/[\[\]\s]+/, '_')
  end

  def to_s
    lines = []
    lines << %(    rdfs:label "#{@label}")
    lines << "    ci #{@name}: #{@types.to_a.join(', ')} ["
    @properties.each do |k, vs|
      vs.each { |v| lines << "        #{k} #{v}" }
    end
    lines << "    ]\n"
    lines.join("\n")
  end
end

desc = Description.new(
  'http://incose.org/pwg/s-star/description/power-converter',
  'power-converter'
)
desc.uses << 'http://www.w3.org/2000/01/rdf-schema'
desc.uses << 'http://incose.org/pwg/s-star/vocabulary/power-interface'

table = CSV.new(ARGF, headers: true)

cis = desc.concept_instances
table.each do |row|

  next unless (if_cell = row['Configured Interface Name'])

  ia_cell = row['Configured Interaction Name']
  ia_label = ia_cell.to_s.split('::').last
  ia_type = ia_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
  ia_ci = cis.fetch(ia_label) { |k| cis[k] = ConceptInstance.new(ia_label, "interface:#{ia_type}") }

  role_cell = row['Configured Role Name']
  role_label = role_cell.to_s.split('::').last
  role_type = role_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
  role_ci = cis.fetch(role_label) { |k| cis[k] = ConceptInstance.new(role_label, "interface:#{role_type}") }

  if_label = if_cell.to_s.split('::').last
  if_type = if_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
  if_ci = cis.fetch(if_label) { |k| cis[k] = ConceptInstance.new(if_label, "interface:#{if_type}") }

  io_cell = row['Configured Input Output Name']
  io_label = io_cell.to_s.split('::').last
  io_type = io_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
  io_ci = cis.fetch(io_label) { |k| cis[k] = ConceptInstance.new(io_label, "interface:#{io_type}") }

  port_cell = row['Configured Port Name']
  port_label = port_cell.to_s.split('::').last
  port_type = port_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
  port_ci = cis.fetch(port_label) { |k| cis[k] = ConceptInstance.new(port_label, "interface:#{port_type}") }

  pd_cell = row['Port Direction']

  soa_cell = row['Configured Input Output Name']
  soa_label = soa_cell.to_s.split('::').last
  soa_type = soa_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
  soa_ci = cis.fetch(soa_label) { |k| cis[k] = ConceptInstance.new(soa_label, "interface:#{soa_type}") }

  if (ar_cell = row['Configured Arch Relat Name'])
    ar_label = ar_cell.to_s.split('::').last
    ar_type = ar_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
    ar_ci = cis.fetch(ar_label) { |k| cis[k] = ConceptInstance.new(ar_label, "interface:#{ar_type}") }

    arr_cell = row['Configured Arch Relat Role Name']
    arr_label = arr_cell.to_s.split('::').last
    arr_type = arr_label.gsub(/ \[.*\z/, '').gsub(/\s+/, '')
    arr_ci = cis.fetch(arr_label) { |k| cis[k] = ConceptInstance.new(arr_label, "interface:#{arr_type}") }
  else
    ar_ci = nil
  end

  role_ci.properties['interface:providesInterface'] << if_ci.name
  role_ci.properties['interface:interactsThrough'] << port_ci.name

  if_ci.properties['interface:permitsFunctionalInteraction'] << ia_ci.name
  if_ci.properties['interface:permitsInputOutput'] << io_ci.name
  if_ci.properties['interface:groups'] << port_ci.name
  if_ci.properties['interface:permitsSOA'] << soa_ci.name
  if_ci.properties['interface:permitsArchitecturalRelationship'] << ar_ci.name if ar_ci

  port_ci.properties['interface:isUsedDuring'] << ia_ci.name
  port_ci.properties[exchanges[pd_cell]] << io_ci.name
  port_ci.properties['interface:isFacilitatedBy'] << soa_ci.name
  port_ci.properties['interface:isLinkedBy'] << ar_ci.name if ar_ci

  if ar_ci
    ar_ci.properties['interface:exemplifies'] << io_ci.name
    ar_ci.properties['interface:hasRole'] << arr_ci.name
  end

end

puts desc.to_s
