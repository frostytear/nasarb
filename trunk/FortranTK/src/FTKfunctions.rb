
def checkForCompiler
 unless ENV['F9X']
  puts <<-ENVIRON

Fortran compiler environment variable 'F9X' not set:

 for bourne-based shells: export F9X=lf95 (in .profile)
      for c-based shells: setenv F9X lf95 (in .login)
             for windows: set F9X=C:\Program Files\lf95 (in autoexec.bat)

  ENVIRON
  exit 1
 end
end


def parseCommandLine

 allTestSuites = Dir["*TS.ftk"]
 allTestSuites.each { |suiteName| suiteName.chomp! "TS.ftk" }

 return allTestSuites if $*.empty?

 testSuitesNotFound = $* - ( $* & allTestSuites )
 if testSuitesNotFound.empty?
  return $*
 else
  print "\n Error: could not find test suite:"
  testSuitesNotFound.each {|testSuiteNotFound| print " #{testSuiteNotFound}"}
  print "\n\n Test suites available in this directory:\n"
  allTestSuites.each { |testSuite| print "  #{testSuite}\n" }
  print "\nUsage: #{File.basename $0} [test names (w/o TS.ftk suffix)]\n\n"
  exit 1
 end

end


def writeTestRunner testSuites

 testRunner = File.new "TestRunner.f90", "w"

 testRunner.puts <<-HEADER
! TestRunner.f90 - runs Fortran mobility test suites
!
! [Dynamically generated by #{File.basename $0} Ruby script #{Time.now}.]

program TestRunner

 HEADER

 testSuites.each { |testSuite| testRunner.puts " use #{testSuite}TS" }

 testRunner.puts <<-DECLARE

 implicit none

 integer :: numTests, numAsserts, numAssertsTested, numFailures
 DECLARE

 testSuites.each do |testSuite|
  testRunner.puts <<-TRYIT

 print *, ""
 print *, "#{testSuite} test suite:"
 call TS#{testSuite}( numTests, numAsserts, numAssertsTested, numFailures )
 print *, "Completed", numTests-numFailures, "of", numTests, &
  "tests comprising", numAssertsTested, "of", numAsserts, "possible asserts."
  TRYIT
 end

 testRunner.puts "\n print *, \"\""
 testRunner.puts "\nend program TestRunner"
 testRunner.close

end

def syntaxError( message, testSuite )
 $stderr.puts "\n\n Syntax error:"
 $stderr.puts "  #{message}, line #$. of #{testSuite}TS.ftk\n\n"
 exit 1
end

def warning( message, testSuite )
 $stderr.puts "\n *Warning: #{message}, line #$. of #{testSuite}TS.ftk"
end

def runTests testSuites

 puts

 sources = testSuites.join(".f90 ") + ".f90"
 tests   = testSuites.join("TS.f90 ") + "TS.f90"

 compile = "#{ENV['F9X']} -o TestRunner #{sources} #{tests} TestRunner.f90"

 if system(compile)
  system "./TestRunner" if File.exists? "TestRunner"
 else
  print "\nCompile failed.\n"
 end

end