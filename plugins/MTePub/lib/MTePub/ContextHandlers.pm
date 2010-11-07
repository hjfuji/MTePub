package MTePub::ContextHandlers;

use strict;
use MT;
use MT::Asset;
use Digest::MD5 qw( md5_hex );
use MT::Util qw( epoch2ts );

sub epub_cover_asset {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    my $cover_asset_id = $blog->fjep_cover_image || 0;
    my $out = '';
    if ($cover_asset_id) {
        my $cover_asset = MT::Asset->load($cover_asset_id);
        my $tokens = $ctx->stash('tokens');
        my $builder = $ctx->stash('builder');
        local $ctx->{__stash}{asset} = $cover_asset;
        $out = $builder->build($ctx, $tokens, { %$cond });
    }
    else {
        $out = $ctx->else($args, $cond);
    }
    return $out;
}

sub epub_id {
    my ($ctx, $args, $cond) = @_;

    require MT::Request;
    my $req = MT::Request->instance;
    my $blog = $ctx->stash('blog');
    my $epoch = $req->stash('FJEPub::TimeStamp');
    $epoch = time unless(defined($epoch));
    return md5_hex($blog->name) . ':' . epoch2ts($blog, $epoch);
}

sub epub_use_category {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_use_category
        ? $ctx->slurp($args, $cond)
        : $ctx->else($args, $cond);
}

sub epub_title_raw {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_title || '';
}

sub epub_author_raw {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_author || '';
}

sub epub_copyright_raw {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_copyright || '';
}

sub epub_publisher_raw {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_publisher || '';
}

sub epub_title {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_title
        ? $blog->fjep_title
        : ($blog->name || '');
}

sub epub_author {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_author
        ? $blog->fjep_author
        : (_blog_authors($ctx) || '');
}

sub epub_publisher {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_publisher
        ? $blog->fjep_publisher
        : $ctx->invoke_handler('epubauthor', $args, $cond);
}

sub epub_copyright {
    my ($ctx, $args, $cond) = @_;

    my $blog = $ctx->stash('blog');
    return $blog->fjep_copyright
        ? $blog->fjep_copyright
        : $ctx->invoke_handler('epubauthor', $args, $cond);
}

sub _blog_authors {
    my $ctx = shift;

    my $vars = $ctx->{__stash}{vars} ||= {};
    local $vars->{fjep_authors};
    my $tmpl = <<HERE;
<\$mt:SetVar name="fjep_authors" value=""\$>
<mt:Authors>
  <mt:SetVarBlock name="fjep_authors" append="1"><\$mt:AuthorDisplayName\$></mt:SetVarBlock>
  <mt:Unless name="__last__">
    <mt:SetVarBlock name="fjep_authors" append="1">, </mt:SetVarBlock>
  </mt:Unless>
</mt:Authors>
HERE

    my $builder = $ctx->stash('builder');
    my $tokens = $builder->compile($ctx, $tmpl);
    my $ret = $builder->build($ctx, $tokens);
    my $authors = $vars->{fjep_authors};
    return $authors;
}

1;
