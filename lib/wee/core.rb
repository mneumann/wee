# The only dependencies of the core classes are:
#
# * Wee::Session.current in class Wee::Presenter#session
# * Wee::DefaultRenderer in Wee::Presenter#renderer_class 
#

# independent files
require 'wee/core/valueholder'
require 'wee/core/snapshot'
require 'wee/core/callback'

# dependent files
require 'wee/core/presenter'
require 'wee/core/decoration'
require 'wee/core/component'
