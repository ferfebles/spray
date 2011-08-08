
def hanoi(n,a,b,c)
   if n-1 > 0
      hanoi(n-1, a, c, b)
   end
   puts "Move disk %s to %s" % [a, b]
   sleep 0.1
   if n-1 > 0
      hanoi(n-1, c, b, a)
    end
end

hanoi(20, :a, :b, :c)
puts "Done!"
