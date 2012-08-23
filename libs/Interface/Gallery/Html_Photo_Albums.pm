package Homyaki::Interface::Gallery::Html_Photo_Albums;

use strict;

use Data::Dumper;

use Homyaki::Tag;
use Homyaki::HTML;
use Homyaki::HTML::Constants;

use Homyaki::Logger;

use Homyaki::Interface;
use base 'Homyaki::Interface::Gallery';

use constant PARAMS_MAP  => {
};

use constant HTML_ALBUMS_PATH => &WWW_PATH . '/albums/';

sub get_form {
	my $self = shift;
	my %h = @_;

	my $params   = $h{params};
	my $errors   = $h{errors};
	my $user     = $h{user};
	my $body_tag = $h{body_tag};

	my $root = $self->SUPER::get_form(
		params   => $params,
		errors   => $errors,
		form_id  => 'blog_form',
		body_tag => $body_tag,
	);

	my $root_tag = $root->{root};
	my $body_tag_ = $root->{body};

	my $permissions = $user->{permissions};


	if (-f &HTML_ALBUMS_PATH . $params->{album_html}) {
		if (open ALBUM_HTML, '<' . &HTML_ALBUMS_PATH . $params->{album_html}) {
			my $album_html = '';
			while (my $str = <ALBUM_HTML>) {
				$album_html .= $str;
			}
			close ALBUM_HTML;

			$body_tag_->add_form_element(
				name   => "html_body",
				type   => &INPUT_TYPE_DIV,
				body   => $album_html,
			);
			
		}
	}


	my $body_tag = $h{body_tag};

	return {
		root => $root_tag,
		body => $body_tag_,
	};
}

sub get_params {
	my $self = shift;
	my %h = @_;

	my $params      = $h{params};
	my $user        = $h{user};
	my $permissions = $user->{permissions};

	my $result = $params;

	return $result;
}

sub get_navigation {
	my $self = shift;
	my %h = @_;

	my $params   = $h{params};
	my $user     = $h{user};
	my $menue_permission = $h{menue_permission};

	my $navigation = {};

	if (-f (&WWW_PATH . '/navigation.html')) {
		if (open NAVIGATION, '<' . &WWW_PATH . '/navigation.html') {
			my $order;
			while (my $str = <NAVIGATION>) {

				if ($str =~ /href="\/albums\/+([^"]+)".*>([^<]+)</){
					$navigation->{$2} = {}
						unless $navigation->{$2};
					$navigation->{$2}->{interface}  = 'gallery';
					$navigation->{$2}->{form}       = 'html_photo_albums';
					$navigation->{$2}->{parameters} = "&album_html=$1";
					$navigation->{$2}->{permission} = $menue_permission;
					$navigation->{$2}->{order}      = ++$order;
				}
			}
			close NAVIGATION;
		} else {
			Homyaki::Logger::print_log('Html_Photo_Albums: Opening file ' .&WWW_PATH . '/navigation.html error: ' . $@);
		}
	}


	return $navigation;
}

1;
