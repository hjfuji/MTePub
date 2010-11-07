package MTePub::Create;

use strict;
use MT;
use MT::Blog;
use MT::Entry;
use MT::Asset;
use MT::Template;
use MT::Util qw( epoch2ts );
use File::Spec;
use Encode;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use XML::Simple;

sub create_epub {
    # initialize
    my $app = shift;

    my $plugin = MT->component('MTePub');
    my $blog_id = $app->param('blog_id');
    if (!$blog_id) {
        return $app->error($plugin->translate('blog_id is not specified.'));
    }
    my $blog = MT::Blog->load($blog_id);
    my $theme = $blog->theme;
    return $app->error($plugin->translate('This theme doesn\'t support EPUB.'))
        unless $theme->{required_components}->{MTePub};

    my $blog_url = $blog->site_url;
    $blog_url .= '/' unless $blog_url =~ m!/$!;
    my $str;

    # print header
    $app->{no_print_body} = 1;
    local $| = 1;
    $app->send_http_header('text/html');
    $app->print_encode($app->build_page('create_start.tmpl'));

    # create epub filename
    my $now = time;
    my $ts = epoch2ts($blog, $now);
    my $temp_dir = $app->config('TempDir');
    my $zip_file = "epub${ts}.epub";
    my $zip_name = File::Spec->catfile($temp_dir, $zip_file);
    my $ctr = 1;
    my $fmgr = $blog->file_mgr;
    while ($fmgr->exists($zip_name)) {
        $zip_file = "epub${ts}-${ctr}.epub";
        $zip_name = File::Spec->catfile($temp_dir, $zip_file);
        $ctr++;
    }

    # try creating epub
    my %param;
    eval {
        # create zip
        my $zip = Archive::Zip->new();

        # add mimetype to zip
        my $mimetype = $zip->addString('application/epub+zip', 'mimetype');
        $mimetype->desiredCompressionMethod(COMPRESSION_STORED);
        $app->print_encode('<li>' . $plugin->translate("Added file '[_1]'", 'mimetype') . '</li>');

        # add container.xml to zip
        $str = <<HERE;
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>
HERE
        $zip->addString($str, 'META-INF/container.xml');
        $app->print_encode('<li>' . $plugin->translate("Added file '[_1]'", 'container.xml') . '</li>');

        # rebuild index templates for epub
        require MT::Request;
        my $req = MT::Request->instance;
        $req->stash('FJEPub::TimeStamp', $now);
        my @tmpl_names = ('content.opf', 'toc.ncx');
        for my $tmpl_name (@tmpl_names) {
            my $tmpl = MT::Template->load({
                blog_id => $blog_id,
                name => $tmpl_name,
            });
            unless(defined(
                $app->rebuild_indexes(
                    BlogID => $blog_id,
                    Template => $tmpl,
                    Force => 1)
            )) {
                $param{msg} = $plugin->translate('Template [_1] rebuild error : ', $tmpl_name) . $app->publish_error();
                die;
            }
        }

        # add index files to zip
        my $cont_opf;
        my @index_files = (
            { name => 'content.opf', i18n => 'content.opf' },
            { name => 'toc.ncx', i18n => 'toc.ncx' },
            { name => 'styles.css', i18n => $plugin->translate('Stylesheet') },
            { name => 'index.html', i18n => $plugin->translate('Cover') },
            { name => 'content.html', i18n => $plugin->translate('Contents') },
        );
        for my $index_file (@index_files) {
            my $filename = File::Spec->catfile($blog->site_path, $index_file->{name});
            $str = $fmgr->get_data($filename);
            unless (defined($str)) {
                $param{msg} = $plugin->translate('Read file error : [_1]', $index_file->{i18n});
                die;
            }
            _conv_relative(\$str, $blog_url);
            if ($index_file->{name} eq 'content.opf') {
                $cont_opf = $str;
            }
            $zip->addString($str, 'OEBPS/' . $index_file->{name});
            $app->print_encode('<li>' . $plugin->translate("Added file '[_1]'", $index_file->{i18n}) . '</li>');

        }

        # parse xml
        my $opf = XMLin($cont_opf);
        my $items = $opf->{manifest}->{item};
        unless(defined($items)) {
            $param{msg} = $plugin->translate('Not exist items in content.opf');
            die;
        }

        # add content files to zip
        my $site_path = $blog->site_path;
        $site_path .= '/' if ($site_path !~ /\/$/);
        for my $key (keys %$items) {
            my $filename = $items->{$key}->{href};
            my $filepath = File::Spec->catfile($site_path, $filename);
            if ($key =~ /item(\d*)/) {
                # add entry to zip
                my $entry = MT::Entry->load($1);
                $str = $fmgr->get_data($filepath);
                unless (defined($str)) {
                    $param{msg} = $plugin->translate('Read entry error : [_1]', $entry->title);
                    die;
                }
                _conv_relative(\$str, $blog_url);
                $zip->addString($str, 'OEBPS/' . $filename);
                $app->print_encode('<li>' . $plugin->translate("Added entry '[_1]'", $entry->title) . '</li>');
            }
            if ($key =~ /cat(\d*)/) {
                # add entry to zip
                my $cat = MT::Category->load($1);
                $str = $fmgr->get_data($filepath);
                unless (defined($str)) {
                    $param{msg} = $plugin->translate('Read category error : [_1]', $cat->label);
                    die;
                }
                _conv_relative(\$str, $blog_url);
                $zip->addString($str, 'OEBPS/' . $filename);
                $app->print_encode('<li>' . $plugin->translate("Added category '[_1]'", $cat->label) . '</li>');
            }
            elsif ($key =~ /asset(\d*)/) {
                # add asset to zip
                my $asset = MT::Asset->load($1);
                unless(defined($zip->addFile($filepath, 'OEBPS/' . $filename))) {                    $param{msg} = $plugin->translate('Add asset error : [_1]', $asset->label);
                    die;
                }
                $app->print_encode('<li>' . $plugin->translate("Added asset '[_1]'", $asset->label) . '</li>');
            }
        }

        # write to zipfile
        if ($zip->writeToFileNamed($zip_name) == AZ_OK) {
            $param{msg} = $plugin->translate("ePub file is successfully saved.<br />\nDownloading of the epub file will start automatically in a few seconds.");
        }
        else {
            $param{msg} = $plugin->translate('ePub file save error.');
            die;
        }
    };
    $param{error} = 1 if ($@);
    $param{filename} = $zip_file;
    $param{magic_token} = $app->make_magic_token;

    # print footer
    $app->print_encode($app->build_page('create_end.tmpl', \%param));
    1;
}

sub download_epub {
    my $app = shift;
    $app->validate_magic() or return;

    # initialize
    my $filename  = $app->param('filename');
    my $temp_dir = $app->config('TempDir');
    my $zip_name = File::Spec->catfile($temp_dir, $filename);

    # download
    if ( open( my $fh, "<", MT::FileMgr::Local::_local($zip_name) ) ) {
        binmode $fh;
        $app->{no_print_body} = 1;
        $app->set_header( "Content-Disposition" => 'attachment; filename="'
                . $filename
                . '"' );
        $app->send_http_header('application/epub+zip');
        my $data;
        while ( read $fh, my ($chunk), 8192 ) {
            $data .= $chunk;
        }
        close $fh;
        $app->print( $data );
#        $app->log(
#            {
#                message => $app->translate(
#                    '[_1] successfully downloaded backup file ([_2])',
#                    $app->user->name, $fname
#                ),
#                level    => MT::Log::INFO(),
#                class    => 'system',
#                category => 'restore'
#            }
#        );
        unlink $zip_name;
    }
    else {
        $app->errtrans('Specified file was not found.');
    }
}

# convert absolute url to relative url
sub _conv_relative {
    my ($str, $blog_url) = @_;

    $$str =~ s/href\s*="${blog_url}(.*)"/href="$1"/g;
    $$str =~ s/src\s*="${blog_url}(.*)"/src="$1"/g;
    $$str =~ s/url\s*\(\s*(['"]?)${blog_url}([^'"]*?)\1?\s*\)/url($2)/g;
    $$str = Encode::encode('utf8', $$str);
}

1;
