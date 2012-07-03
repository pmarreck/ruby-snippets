#!/usr/bin/env ruby
['socket','yaml'].each{|f| require f};def q x;$m.find{|o|o.t==:p&&x==o.n};end
def a r,t;$m.find_all{|o|t==o.t&&(!r||r==o.l)};end;def g z;a(nil,:p).each{|p|
p.p z};end;class O;attr_accessor :i,:n,:l,:e,:s,:t;def initialize n,l=nil,t=:r
@n,@l,@i,@t=n,l,$d+=1,t;@e={};end;def p s;@s.puts(s)if @s;end;def y m
v=$m.find{|o|@l==o.i};t=v.e.keys;case m;when/^q/;@s.close;@s=nil;
File.open('d.yml','w'){|f|YAML::dump $m,f};when/^h/;p "i,l,d,g,c,h,q,<exit>,O,R" 
when/^i/;a(@i,:o).each{|o|p o.n};when/^c.* (.*)/;g "#{@n}:#{$1}" 
when/^g/;a(@l,:o).each{|q|q.l=@i};when/^d/;a(@i,:o).each{|q|q.l=@l}
when/^O (.*)/;$m<<O.new($1,@l,:o);when/^R (.*) (.*) (.*)/;$m<<d=O.new($1)
v.e[$2]=d.i;d.e[$3]=v.i;when/^l/;p v.n;(a(@l,:p)+a(@l,:o)).each{|x|
p x.n if x.s||x.t==:o};p t.join('|');when/(^#{t.empty? ? "\1" : t.join('|^')})/
@l=v.e[$1];else;p "?";end;end;end;test ?e,'d'||begin;$d=0;$m=[O.new("Home")]
end;$m=YAML::load_file 'd.yml';$d=$m.size;z=TCPServer.new 0,4000;while k=z.accept
Thread.new(k){|s|s.puts "Name";s.gets;l=$_.chomp;d=q l;$m<<d=O.new(l,1,:p)if !d
d.s=s;while s.gets;d.y $_.chomp;end;};end
