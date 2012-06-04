package Homyaki::Task_Manager::Task::Build_Gallery::Interface_Builder::HTML_Albums;

use strict;

use Net::FTP;
use Homyaki::String qw(handle_template);

use constant ALBUMS_URI           => '/albums/';

use constant TMPL_PATH            => '/var/homyaki/gallery/';
use constant TEMPORARY_PATH       => &TMPL_PATH . '/tmp/';
use constant NAVIGATION_TMPL      => &TMPL_PATH . 'navigation.tmpl';
use constant NAVIGATION_ITEM_TMPL => &TMPL_PATH . 'navigation_item.tmpl';
use constant ALBUM_TMPL           => &TMPL_PATH . 'album.tmpl';
use constant ALBUM_ITEM_TMPL      => &TMPL_PATH . 'album_item.tmpl';


use constant WEEK_DAY_MAP => {
	1 => 'Monday',
	2 => 'Tuesday',
	3 => 'Wednesday',
	4 => 'Thursday',
	5 => 'Friday',
	6 => 'Saturday',
	7 => 'Sunday',
};

sub get_new_album_name {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());

	$wday = &WEEK_DAY_MAP->{$wday};
	$year = 1900 + $year;
	$sec  = sprintf('%02d',$sec);
	$min  = sprintf('%02d',$min);
	$hour = sprintf('%02d',$hour);
	$mday = sprintf('%02d',$mday);
	$mon++;
	$mon  = sprintf('%02d',$mon);

	return "This pictures or comments was changed on $wday $mday.$mon.$year";
}

sub upload_file {
	my $source_path = shift;
	my $dest_path   = shift;
	my $ftp         = shift;
	my $index       = 1;
	
	if ($dest_path && $dest_path ne '/') {
		$ftp->put($source_path, $dest_path)
			or Homyaki::Logger::print_log("Build_Gallery: Error: (Cannot put $source_path to $dest_path) " . $ftp->message);
	} else {
		$ftp->put($source_path)
			or Homyaki::Logger::print_log("Build_Gallery: Error: (Cannot put $source_path to $dest_path) " . $ftp->message);
	}
}

sub make {
	my $class = shift;
	my %h = @_;

		
	my $params     = $h{params};
	my $albums     = $h{albums};
	my $new_images = $h{new_images};


	my $ftp = Net::FTP->new($params->{web_path}, Debug => 0)
		or die "Cannot connect to some.host.name: $@";
		
	$ftp->login($params->{web_login}, $params->{web_password})
		or die "Cannot login ", $ftp->message;

	my $album_index = 1;
	my $navigation_list_html = '';

	foreach my $album (({name => get_new_album_name(), images => $new_images},(@{$albums}))){

		my $album_file_name = "album_$album_index.html";

		$navigation_list_html .= handle_template(
			template_path => &NAVIGATION_ITEM_TMPL,
			parameters    => {
				HEADER => $album->{name},
				URI    => &ALBUMS_URI . '/' . $album_file_name,
			}
		);

		my $album_list_html = '';
		foreach my $image (@{$album->{images}}){

			$album_list_html .= handle_template(
				template_path => &ALBUM_ITEM_TMPL,
				parameters    => {
					COMMENT   => $image->{resume},
					IMAGE_URI => $params->{images_path} . $image->{image},
				}
			);
		}

		my $album_html = handle_template(
			template_path => &ALBUM_TMPL,
			parameters    => {
				HEADER      => $album->{name},
				IMAGES_LIST => $album_list_html,
			}
		);

		if (open ALBUM_HTML, '>' . &TEMPORARY_PATH . '/' . $album_file_name) {
			print ALBUM_HTML $album_html;
			close ALBUM_HTML;

			upload_file(&TEMPORARY_PATH . '/' . $album_file_name, &ALBUMS_URI . '/' . $album_file_name, $ftp);
		} else {
			Homyaki::Logger::print_log('cant open ' . &TEMPORARY_PATH . '/' . $album_file_name . " $!");
		}

		$album_index++;
	}

	my $navi_html = handle_template(
		template_path => &NAVIGATION_TMPL,
		parameters    => {
			NAVIGATION_LIST => $navigation_list_html,
		}
	);

	if (open INDEX_HTML, '>' . &TEMPORARY_PATH . '/navigation.html') {
		print INDEX_HTML $navi_html;
		close INDEX_HTML;

		upload_file(&TEMPORARY_PATH . '/navigation.html', &ALBUMS_URI . '/navigation.html', $ftp);
	} else {
		Homyaki::Logger::print_log('cant open ' . &TEMPORARY_PATH . " navigation.html $!");
	}


	$ftp->quit;
}

1;
