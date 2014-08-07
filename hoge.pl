use strict;
use warnings;
use XML::Diver;
use HTML::Tidy::libXML;
use Furl;
use Data::Dumper;

my $agent = Furl->new(agent => 'Asamashi-LinKu/0.01', timeout => 30);
my $tidy = HTML::Tidy::libXML->new;

my $res = $agent->get('http://www.amazon.co.jp/s/?field-keywords=%E3%83%9F%E3%83%8D%E3%83%A9%E3%83%AB%E3%82%A6%E3%82%A9%E3%83%BC%E3%82%BF%E3%83%BC');
die $res->status_line unless $res->is_success;

my $dom = $tidy->html2dom($res->content);
my $diver = XML::Diver->new($dom);
printf("%s\n", $diver->dive('//*[@id="result_0"]/h3/a')->each(sub{shift->text})->[0]);

