require 'wee'
require 'wee/adaptors/webrick' 
require 'wee/utils'

class RadioTest < Wee::Component
  def initialize
    super
    add_decoration(Wee::PageDecoration.new("Radio Test"))
  end

  def render
    grp1 = r.new_radio_group
    grp2 = r.new_radio_group

    r.form do
      r.paragraph
      r.text "Group1"
      r.break

      r.text "R1: "
      r.radio_button.group(grp1).checked.callback { p "G1.R1" }
      r.break

      r.text "R2: "
      r.radio_button.group(grp1).callback { p "G1.R2" }

      r.paragraph
      r.text "Group2"
      r.break

      r.text "R1: "
      r.radio_button.group(grp2).checked.callback { p "G2.R1" }
      r.break

      r.text "R2: "
      r.radio_button.group(grp2).callback { p "G2.R2" }

      r.paragraph
      r.submit_button.value('Submit')
    end
  end
end

Wee::WEBrickAdaptor.register('/app' => Wee::Utils.app_for(RadioTest)).start 
