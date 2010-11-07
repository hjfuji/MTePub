package MTePub::L10N::ja;

use strict;
use base 'MTePub::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
    'Hajime Fujimoto' => '藤本　壱',
    'Create ePub document on Movable Type.' => 'Movable TypeでEPUB文書を作成します。',

    # Callback.pm
    'Restore cover image id of blog [_1]' => 'ブログ[_1]の表紙画像のIDを復元しました。',

    # Create.pm
    'blog_id is not specified.' => 'blog_idが指定されていません。',
    "Added file '[_1]'" => 'ファイル「[_1]」を追加しました。',
    "Added entry '[_1]'" => 'ブログ記事「[_1]」を追加しました。',
    "Added category '[_1]'" => 'カテゴリ「[_1]」を追加しました。',
    "Added asset '[_1]'" => 'アイテム「[_1]」を追加しました。',
    'Template [_1] rebuild error : ' => 'テンプレート「[_1]」の再構築に失敗しました。',
    'Read file error : [_1]' => 'ファイル「[_1]」の読み込みに失敗しました。',
    'Read entry error : [_1]' => 'ブログ記事「[_1]」の読み込みに失敗しました。',
    'Read category error : [_1]' => 'カテゴリ「[_1]」の読みこみに失敗しました。',
    'Not exist manifest in content.opf' => 'content.opfのmanifest部分が存在しません。',
    'Add asset error : [_1]' => 'アイテム「[_1]」の追加に失敗しました。',
    "ePub file is successfully saved.<br />\nDownloading of the epub file will start automatically in a few seconds." => "EPUBファイルを保存しました。<br />\nまもなく自動的にダウンロードが始まります。",
    'ePub file save error.' => 'EPUBファイルの保存に失敗しました。',
    'Stylesheet' => 'スタイルシート',
    'Cover' => '表紙',
    'Contents' => '目次',

    # Setting.pm
    'This theme doesn\'t support EPUB.' => 'このテーマはEPUBをサポートしていません。',

    # create_start.tmpl
    'Create ePub' => 'EPUBを出力',
    'Creating...' => '出力中...',
    'Creating ePub...' => 'EPUBを出力中...',

    # setting_epub.tmpl
    'Title' => 'タイトル',
    'Title of this ePub.' => 'EPUBのタイトル',
    'Author' => '著者',
    'Author of this ePub.' => 'EPUBの著者',
    'Publisher' => '発行元',
    'Publisher of this ePub.' => 'EPUBの発行元',
    'Copyright' => '著作権者',
    'Copyright of this ePub.' => 'EPUBの著作権者',
    'ePub Setting' => 'EPUBの設定',
    'Your changes have been saved.' => '設定を保存しました。',
    '<a href="[_1]" class="mt-rebuild" title="Rebuild blog">Rebuild blog</a> to apply changes.' => '設定を適用するために、<a href="[_1]" class="mt-rebuild" title="ブログを再構築">ブログを再構築</a>してください。',
    'Save Changes' => '変更を保存',
    'Cover image' => '表紙の画像',
    'Cover image of this ePub.' => 'EPUBの表紙の画像',
    'Select cover image' => '表紙の画像を選択',
    'Remove cover image' => '表紙の画像を削除',
    'Use category as chapter' => 'カテゴリを章として利用',
    'If you use category as chapter, check this box.' => 'カテゴリを章として利用する場合はチェックをオンにしてください。',
);

1;
