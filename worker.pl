#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Log::Minimal;
use AnyEvent;

use File::Spec;
use File::Basename 'dirname';
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'),
    File::Spec->catdir(dirname(__FILE__), 'local', 'lib'),
    glob(File::Spec->catdir(dirname(__FILE__), 'submodule', '*', 'lib')),
);
use Unruly;

use Furl;
use URI;
use XML::Diver;
use HTML::Tidy::libXML;

my $bot_name = $ENV{BOT_NAME} || '麻増凛空';
my @tags = qw/PUBLIC/;

my $tidy = HTML::Tidy::libXML->new;
my $agent = Furl->new(agent => 'Asamashi-LinKu/0.01', timeout => 20);
my $base_url = 'http://www.amazon.co.jp/';

my @not_found = qw/
    …ないみたい
    …みつからない
    …ない
    …なかった
/;

my @bad_list = qw/
    …調子わるい
    …なんか、駄目
    …無理みたい
    …あとにして
/;

my $bot = Unruly->new(
    url  => 'http://yancha.hachiojipm.org',
    tags => {map {($_ => 1)} @tags},
    ping_intervals => 15,
);

unless( $bot->login($bot_name) ) {
    critf('Login failure');
    exit;
}

my $cv = AnyEvent->condvar;

$bot->run(sub {
    my ($client, $socket) = @_;

    infof('runnings at pid %s', $$);

    $socket->on('user message' => sub {
        my ($_socket, $message) = @_;

        if ($message->{is_message_log}) {
            ### ++などに反応させたい場合はここにロジックを書く
        }
        else {
            unless ($message->{nickname} eq $bot_name) {
                if (my ($keyword) = $message->{text} =~ /^(?:amazon|アマゾン|a)\s(.+)\s#/) {

                    my $url = url('/s/', 'field-keywords' => $keyword);
                    my $res = $agent->get($url);

                    my $response = $res->is_success ? fetch_item($res->content) : bad_status();
                    
                    $bot->post($response, @tags);
                }
            }
        }
    });

});

$cv->wait;

sub url {
    my ($path, %attr) = @_;
    my $uri = URI->new($base_url);
    $uri->path($path || '/');
    $uri->query_form(%attr) if %attr;
    $uri->as_string;
}

sub bad_status {
    $bad_list[int(rand($#bad_list+1))];
}

sub not_found {
    $not_found[int(rand($#bad_list+1))];
}

sub fetch_item {
    my ($content) = @_;
    my $dom = $tidy->html2dom($content, 'utf8');
    my $diver = XML::Diver->new($dom);
    my $link = $diver->dive('//*[@id="result_0"]/h3/a')->each(sub{shift->attr('href')})->[0] || not_found();
    return $link;
}


