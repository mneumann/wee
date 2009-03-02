$LOAD_PATH.unshift "../lib"
require 'rubygems'
require 'wee'
require 'rack'

class RadioTest < Wee::Component
  def initialize
    super
    add_decoration(Wee::PageDecoration.new("Radio Test"))
  end

  def render(r)
    grp1 = r.new_radio_group
    grp2 = r.new_radio_group

    r.form do
      r.paragraph
      r.text "Group1"
      r.break

      r.text "R1: "
      r.radio_button.group(grp1).checked(@g1.nil? || @g1 == 'R1').callback { @g1 = 'R1'; p "G1.R1" }
      r.break

      r.text "R2: "
      r.radio_button.group(grp1).checked(@g1 == 'R2').callback { @g1 = 'R2'; p "G1.R2" }

      r.paragraph
      r.text "Group2"
      r.break

      r.text "R1: "
      r.radio_button.group(grp2).checked(@g2.nil? || @g2 == 'R1').callback { @g2 = 'R1'; p "G2.R1" }
      r.break

      r.text "R2: "
      r.radio_button.group(grp2).checked(@g2 == 'R2').callback { @g2 = 'R2'; p "G2.R2" }

      r.paragraph
      r.submit_button.value('Submit')
    end
  end
end

Wee.run(RadioTest)
