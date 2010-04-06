use inc::Module::Install;

# Define metadata
name           'Keyword';
all_from       'lib/Devel/Declare/Keyword.pm';

# Specific dependencies
requires       'Devel::Declare'  => '0.0';
requires       'B::Hooks::EndOfScope'  => '0.0';
test_requires  'Test::More'  => '0.42';
#recommends     'Text::CSV_XS'=> '0.50';
no_index       'directory'   => 'examples';
#install_script 'myscript';
tests "t/*.t t/usecase/*.t";

WriteAll;
