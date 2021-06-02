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
    @extends.each { |u| lines << "    extends <#{u}>\n" }
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
    label.gsub(/[\[\]\s]+/, '_')
  end

  def self.label_to_superclass(label)
    label.gsub(/ \[.*\z/, '')
  end

  def self.make_label(s)
    s
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

  ia_c = nil
  if (ia_cell = row['Configured Interaction Name'])
    ia_label = Concept.make_label(ia_cell)
    ia_c = cs.fetch(ia_label) { |k| cs[k] = Concept.new(ia_label, 'interface:FunctionalInteraction') }

    if (sc_label = Concept.label_to_superclass(ia_label)) != ia_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:FunctionalInteraction') }
      ia_c.types << sc.name
    end
  end

  sy_c = provides_if_rest_c = int_thr_rest_c = nil
  if (role_cell = row['Configured Role Name'])
    role_label = Concept.make_label(role_cell)
    sy_c = cs.fetch(role_label) { |k| cs[k] = Concept.new(role_label, 'interface:System') }

    if (sc_label = Concept.label_to_superclass(role_label)) != role_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:System') }
      sy_c.types << sc.name
    end

    provides_if_rest_label = "#{role_label} Provides Interface"
    provides_if_rest_c = cs.fetch(provides_if_rest_label) { |k| cs[k] = Concept.new(provides_if_rest_label, 'interface:Interface') }
    sy_c.rest_all['interface:providesInterface'] = provides_if_rest_c.name

    int_thr_rest_label = "#{role_label} Interacts Through"
    int_thr_rest_c = cs.fetch(int_thr_rest_label) { |k| cs[k] = Concept.new(int_thr_rest_label, 'interface:Port') }
    sy_c.rest_all['interface:interactsThrough'] = int_thr_rest_c.name
  end

  if_c = permits_fi_rest_c = permits_io_rest_c = permits_ar_rest_c = groups_rest_c = permits_soa_rest_c = nil
  if (if_cell = row['Configured Interface Name'])
    if_label = Concept.make_label(if_cell)
    if_c = cs.fetch(if_label) { |k| cs[k] = Concept.new(if_label, 'interface:Interface') }

    if (sc_label = Concept.label_to_superclass(if_label)) != if_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:Interface') }
      if_c.types << sc.name
    end

    permits_fi_rest_label = "#{if_label} Permits Functional Interaction"
    permits_fi_rest_c = cs.fetch(permits_fi_rest_label) { |k| cs[k] = Concept.new(permits_fi_rest_label, 'interface:FunctionalInteraction') }
    if_c.rest_all['interface:permitsFunctionalInteraction'] = permits_fi_rest_c.name

    permits_io_rest_label = "#{if_label} Permits Input Output"
    permits_io_rest_c = cs.fetch(permits_io_rest_label) { |k| cs[k] = Concept.new(permits_io_rest_label, 'interface:InputOutput') }
    if_c.rest_all['interface:permitsInputOutput'] = permits_io_rest_c.name

    permits_ar_rest_label = "#{if_label} Permits Architectural Relationship"
    permits_ar_rest_c = cs.fetch(permits_ar_rest_label) { |k| cs[k] = Concept.new(permits_ar_rest_label, 'interface:ArchitecturalRelationship') }
    if_c.rest_all['interface:permitsArchitecturalRelationship'] = permits_ar_rest_c.name

    groups_rest_label = "#{if_label} Groups"
    groups_rest_c = cs.fetch(groups_rest_label) { |k| cs[k] = Concept.new(groups_rest_label, 'interface:Port') }
    if_c.rest_all['interface:groups'] = groups_rest_c.name

    permits_soa_rest_label = "#{if_label} Permits SOA"
    permits_soa_rest_c = cs.fetch(permits_soa_rest_label) { |k| cs[k] = Concept.new(permits_soa_rest_label, 'interface:SystemOfAccess') }
    if_c.rest_all['interface:permitsSOA'] = permits_soa_rest_c.name
  end

  io_c = exemplifies_rest_c = nil
  if (io_cell = row['Configured Input Output Name'])
    io_label = Concept.make_label(io_cell)
    io_c = cs.fetch(io_label) { |k| cs[k] = Concept.new(io_label, 'interface:InputOutput') }

    if (sc_label = Concept.label_to_superclass(io_label)) != io_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:InputOutput') }
      io_c.types << sc.name
    end

    exemplifies_rest_label = "#{io_label} Exemplifies"
    exemplifies_rest_c = cs.fetch(exemplifies_rest_label) { |k| cs[k] = Concept.new(exemplifies_rest_label, 'interface:ArchitecturalRelationship') }
    io_c.rest_all['interface:exemplifies'] = exemplifies_rest_c.name
  end

  port_c = is_used_during_rest_c = is_facilitated_by_rest_c = is_linked_by_rest_c = nil
  if (port_cell = row['Configured Port Name'])
    port_label = Concept.make_label(port_cell)
    port_c = cs.fetch(port_label) { |k| cs[k] = Concept.new(port_label, 'interface:Port') }

    if (sc_label = Concept.label_to_superclass(port_label)) != port_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:Port') }
      port_c.types << sc.name
    end

    is_used_during_rest_label = "#{port_label} Is Used During"
    is_used_during_rest_c = cs.fetch(is_used_during_rest_label) { |k| cs[k] = Concept.new(is_used_during_rest_label, 'interface:FunctionalInteraction') }
    port_c.rest_all['interface:isUsedDuring'] = is_used_during_rest_c.name

    is_facilitated_by_rest_label = "#{port_label} Is Facilitated By"
    is_facilitated_by_rest_c = cs.fetch(is_facilitated_by_rest_label) { |k| cs[k] = Concept.new(is_facilitated_by_rest_label, 'interface:SystemOfAccess') }
    port_c.rest_all['interface:isFacilitatedBy'] = is_facilitated_by_rest_c.name

    is_linked_by_rest_label = "#{port_label} Is Linked By"
    is_linked_by_rest_c = cs.fetch(is_linked_by_rest_label) { |k| cs[k] = Concept.new(is_linked_by_rest_label, 'interface:ArchitecturalRelationship') }
    port_c.rest_all['interface:isLinkedBy'] = is_linked_by_rest_c.name
  end

  soa_c = nil
  if (soa_cell = row['Configured SOA Name'])
    soa_label = Concept.make_label(soa_cell)
    soa_c = cs.fetch(soa_label) { |k| cs[k] = Concept.new(soa_label, 'interface:SystemOfAccess') }

    if (sc_label = Concept.label_to_superclass(soa_label)) != soa_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:SystemOfAccess') }
      soa_c.types << sc.name
    end
  end

  ar_c = has_role_rest_c = nil
  if (ar_cell = row['Configured Arch Relat Name'])
    ar_label = Concept.make_label(ar_cell)
    ar_c = cs.fetch(ar_label) { |k| cs[k] = Concept.new(ar_label, 'interface:ArchitecturalRelationship') }

    if (sc_label = Concept.label_to_superclass(ar_label)) != ar_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:ArchitecturalRelationship') }
      ar_c.types << sc.name
    end

    has_role_rest_label = "#{ar_label} Has Role"
    has_role_rest_c = cs.fetch(has_role_rest_label) { |k| cs[k] = Concept.new(has_role_rest_label, 'interface:ArchitecturalRelationshipRole') }
    ar_c.rest_all['interface:hasRole'] = has_role_rest_c.name
  end

  arr_c = nil
  if (arr_cell = row['Configured Arch Relat Role Name'])
    arr_label = Concept.make_label(arr_cell)
    arr_c = cs.fetch(arr_label) { |k| cs[k] = Concept.new(arr_label, 'interface:ArchitecturalRelationshipRole') }

    if (sc_label = Concept.label_to_superclass(arr_label)) != arr_label
      sc = cs.fetch(sc_label) { |k| cs[k] = Concept.new(sc_label, 'interface:ArchitecturalRelationshipRole') }
      arr_c.types << sc.name
    end
  end

  if ia_c
    ia_c.types << permits_fi_rest_c.name if permits_fi_rest_c
    ia_c.types << is_used_during_rest_c.name if is_used_during_rest_c
  end

  if if_c
    if_c.types << provides_if_rest_c.name if provides_if_rest_c
  end

  if io_c
    io_c.types << permits_io_rest_c.name if permits_io_rest_c && io_c
  end

  if ar_c
    ar_c.types << permits_ar_rest_c.name if permits_ar_rest_c
    ar_c.types << exemplifies_rest_c.name if exemplifies_rest_c
    ar_c.types << is_linked_by_rest_c.name if is_linked_by_rest_c
  end

  if port_c
    port_c.types << groups_rest_c.name if groups_rest_c
    port_c.types << int_thr_rest_c.name if int_thr_rest_c
  end

  if soa_c
    soa_c.types << permits_soa_rest_c.name if permits_soa_rest_c
    soa_c.types << is_facilitated_by_rest_c.name if is_facilitated_by_rest_c
  end

  if arr_c
    arr_c.types << has_role_rest_c.name if has_role_rest_c
  end

end

puts vocab.to_s

