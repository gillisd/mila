require '/Users/davidgillis/repos/smuggler/smuggler.rb'
Gem.pre_install do
  Gem.done_installing_hooks.delete_if { _1.to_s.match /lib\/rdoc/ }

  Gem.post_install do |*args, **kwargs|
#    binding.irb
    gem_name = args.first.spec.name
    marshalled = Marshal.dump args.first rescue nil
    unless marshalled.nil?
      puts "writing #{gem_name}"
      File.open("#{gem_name}.marsh", 'w') do |f|
        f.binmode
        f.write(marshalled)
      end
    end
  end
end
