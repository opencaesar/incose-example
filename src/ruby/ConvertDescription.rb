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
    label.gsub(/[\[\]\s]+/, '_').downcase
  end

  def self.make_label(s)
    s
  end

  def self.label_to_type(label)
    label.gsub(/[\[\]\s]+/, '_')
  end

  def to_s
    lines = []
    lines << "    ci #{@name}: #{@types.to_a.join(', ')} ["
    lines << %(        interface:hasIdentifier "#{@label}")
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
  ia_label = ConceptInstance.make_label(ia_cell)
  ia_type = ConceptInstance.label_to_type(ia_label)
  ia_ci = cis.fetch(ia_label) { |k| cis[k] = ConceptInstance.new(ia_label, "power-interface:#{ia_type}") }

  role_cell = row['Configured Role Name']
  role_label = ConceptInstance.make_label(role_cell)
  role_type = ConceptInstance.label_to_type(role_label)
  role_ci = cis.fetch(role_label) { |k| cis[k] = ConceptInstance.new(role_label, "power-interface:#{role_type}") }

  if_label = ConceptInstance.make_label(if_cell)
  if_type = ConceptInstance.label_to_type(if_label)
  if_ci = cis.fetch(if_label) { |k| cis[k] = ConceptInstance.new(if_label, "power-interface:#{if_type}") }

  io_cell = row['Configured Input Output Name']
  io_label = ConceptInstance.make_label(io_cell)
  io_type = ConceptInstance.label_to_type(io_label)
  io_ci = cis.fetch(io_label) { |k| cis[k] = ConceptInstance.new(io_label, "power-interface:#{io_type}") }

  port_cell = row['Configured Port Name']
  port_label = ConceptInstance.make_label(port_cell)
  port_type = ConceptInstance.label_to_type(port_label)
  port_ci = cis.fetch(port_label) { |k| cis[k] = ConceptInstance.new(port_label, "power-interface:#{port_type}") }

  pd_cell = row['Port Direction']

  soa_cell = row['Configured SOA Name']
  soa_label = ConceptInstance.make_label(soa_cell)
  soa_type = ConceptInstance.label_to_type(soa_label)
  soa_ci = cis.fetch(soa_label) { |k| cis[k] = ConceptInstance.new(soa_label, "power-interface:#{soa_type}") }

  if (ar_cell = row['Configured Arch Relat Name'])
    ar_label = ConceptInstance.make_label(ar_cell)
    ar_type = ConceptInstance.label_to_type(ar_label)
    ar_ci = cis.fetch(ar_label) { |k| cis[k] = ConceptInstance.new(ar_label, "power-interface:#{ar_type}") }

    arr_cell = row['Configured Arch Relat Role Name']
    arr_label = ConceptInstance.make_label(arr_cell)
    arr_type = ConceptInstance.label_to_type(arr_label)
    arr_ci = cis.fetch(arr_label) { |k| cis[k] = ConceptInstance.new(arr_label, "power-interface:#{arr_type}") }
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
    io_ci.properties['interface:exemplifies'] << ar_ci.name
    ar_ci.properties['interface:hasRole'] << arr_ci.name
  end

end

puts desc.to_s
