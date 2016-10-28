require 'spec_helper'

#Puppet::Util::Log.level = :debug
#Puppet::Util::Log.newdestination(:console)

describe 'ftep::backend', :type => 'class' do
  it { should compile }
  it { should contain_class('ftep::backend') }
  it { should contain_class('ftep::backend::zoo_kernel') }

  it { should contain_package('zoo-kernel').with_name('zoo-kernel') }
  it { should contain_file('/usr/lib/cgi-bin/main.cfg')
                  .with_content(/^serverAddress = https:\/\/forestry-tep.eo.esa.int\/zoo$/)
                  .with_content(/^dataPath = \/var\/www\/temp/)
  }
end
