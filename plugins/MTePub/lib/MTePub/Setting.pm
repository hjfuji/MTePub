package MTePub::Setting;

use MT;
use MT::Blog;
use MT::Asset;
use MT::Util;

sub setting_epub {
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

    # show page
    my %params;
    my $token = $app->make_magic_token;
    $params{blog_id} = $blog_id;
    $params{rebuild_url} = $app->mt_uri . '?__mode=rebuild_confirm&amp;blog_id=' . $blog->id;
    $params{saved} = $app->param('saved');
    $params{magic_token} = $token;
    my $cover_asset_id = $blog->fjep_cover_image || 0;
    $params{cover_asset_id} = $cover_asset_id;
    $params{title} = $blog->fjep_title || '';
    $params{author} = $blog->fjep_author || '';
    $params{publisher} = $blog->fjep_publisher || '';
    $params{copyright} = $blog->fjep_copyright || '';
    $params{category} = $blog->fjep_use_category || 0;
    if ($cover_asset_id) {
        my $asset = MT::Asset->load($cover_asset_id);
        $params{cover} = _cover_html($asset);
    }
    $app->build_page('setting_epub.tmpl', \%params);
}

sub save_setting {
    # initialize
    my $app = shift;
    $app->validate_magic() or return;

    my $plugin = MT->component('MTePub');
    my $blog_id = $app->param('blog_id');
    if (!$blog_id) {
        return $app->error($plugin->translate('blog_id is not specified.'));
    }
    my $blog = MT::Blog->load($blog_id);
    my $theme = $blog->theme;
    return $app->error($plugin->translate('This theme doesn\'t support EPUB.'))
        unless $theme->{required_components}->{MTePub};

    # save setting
    my $cover_asset_id = int($app->param('cover_asset_id'));
    $blog->fjep_cover_image($cover_asset_id);
    $blog->fjep_title($app->param('title'));
    $blog->fjep_author($app->param('author'));
    $blog->fjep_publisher($app->param('publisher'));
    $blog->fjep_copyright($app->param('cpyright'));
    $blog->fjep_use_category(int($app->param('category')));
    $blog->save;

    # redirect to setting page
    $app->redirect(
        $app->uri(mode => 'fjep_setting_epub',
                  args => { blog_id => $blog_id,
                            saved => 1 })
    );
}

sub upload_cover {
    my $app = shift;

    require MT::CMS::Asset;
    my ($asset, $bytes) = MT::CMS::Asset::_upload_file(
        $app,
        @_,
        require_type => 'image',
    );
    return if !defined $asset;
    return $asset if !defined $bytes;  # whatever it is

    my $blog_id = $app->param('blog_id');
    $asset->tags('@coverpic');
    $asset->created_by($app->user->id);
    $asset->blog_id($blog_id);
    $asset->save;

    $app->forward('fjep_asset_cover', { asset => $asset, blog_id => $blog_id });
}

sub asset_cover {
    my $app = shift;
    my ($param) = @_;

    my ($id, $asset);
    if ($asset = $param->{asset}) {
        $id = $asset->id;
    }
    else {
        $id = $param->{asset_id} || scalar $app->param('id');
        $asset = $app->model('asset')->lookup($id);
    }

    my $thumb_html = _cover_html($asset, 'enc');
    $app->load_tmpl(
        'asset_cover.tmpl',
        {
            asset_id   => $id,
            edit_field => $app->param('edit_field') || '',
            coverpic   => $thumb_html,
        },
    );
}

sub _cover_html {
    my ($asset, $mode) = @_;

    my $url = $asset->url;
    my $w = $asset->image_width;
    my $h = $asset->image_height;
    if ($w > 150) {
        my $rate = $w / 150;
        $w = 150;
        $h = int($h / $rate);
    }
    return sprintf q{<img src="%s" width="%d" height="%d" alt="" />},
           ($mode eq 'enc') ? MT::Util::encode_html($url) : $url, $w, $h;
}

1;
