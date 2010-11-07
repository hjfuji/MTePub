package MTePub::Callback;

use strict;
use MT;

sub can_menu {
    my $app = MT->instance;
    my $blog_id = $app->param('blog_id');
    return 0 if (!$blog_id);
    require MT::Blog;
    my $blog = MT::Blog->load($blog_id);
    return 0 if (!$blog);
    my $theme = $blog->theme;
    return 0 unless $theme->{required_components}->{MTePub};
    return 1;
}

sub footer {
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = MT->component('MTePub');

    my $blog = $app->blog;
    return if (!$blog || ($blog && !$blog->is_blog ));
    my $theme = $blog->theme;
    return unless $theme->{required_components}->{MTePub};

    # search <mt:var name="jq_js_include">
    my $elements = $tmpl->getElementsByTagName('var');
    my $host_node;
    for my $element (@$elements) {
        if($element->attributes->{name} eq 'jq_js_include') {
            $host_node = $element;
            last;
        }
    }

    # append js
    if ($host_node) {
        my $node = $tmpl->createElement('setvarblock', { 'name' => 'jq_js_include', 'append' => 1 });

        my $add_tmpl = <<HERE;
(function(){
    var rebuild_button = jQuery('#rebuild-site');
    if (rebuild_button.length) {
        rebuild_button.before('<li id="create-epub" class="nav-link"><a href="<\$mt:var name="mt_url"\$>?__mode=fjep_create_epub&amp;blog_id=<\$mt:var name"blog_id"\$>" title="<__trans phrase="Create ePub">" id="create_epub_link" style="background-image: url(<mt:var name="static_uri">plugins/MTePub/images/nav-icon-epub.png)"><span style="display : none;"><__trans phrase="Create ePub"></span></a></li>');
    }
})();
HERE
        my $plugin = MT->component('MTePub');
        $add_tmpl = $plugin->translate_templatized($add_tmpl);
        $node->innerHTML($add_tmpl);
        $tmpl->insertBefore($node, $host_node);
    }
}

sub restore {
    my ($cb, $objects, $deferred, $errors, $callback) = @_;
    my $plugin = MT->component('MTePub');

    # get asset ids mapping
    my (%assets, %blogs);
    for my $key ( keys %$objects ) {
        if ($key =~ /^MT::Asset#(\d+)$/) {
            my $old_id = $1;
            my $new_id = $objects->{$key}->id;
            $assets{$old_id} = $new_id;
        }
        elsif ($key =~ /^MT::Blog#(\d+)$/) {
            my $old_id = $1;
            my $new_id = $objects->{$key}->id;
            $blogs{$new_id} = $objects->{$key};
        }
    }

    # replace fjep_cover_image from old asset id to new asset id
    require MT::Blog;
    for my $blog_id (keys %blogs) {
        my $blog = $blogs{$blog_id};
        if ($blog && $blog->fjep_cover_image && $assets{$blog->fjep_cover_image}) {
            $blog->fjep_cover_image($assets{$blog->fjep_cover_image});
            $blog->save;
            $callback->($plugin->translate('Restore cover image id of blog [_1]', $blog->id));
        }
    }
}

1;
