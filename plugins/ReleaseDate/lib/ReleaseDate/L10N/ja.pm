package ReleaseDate::L10N::ja;

use strict;
use MT;
use base 'ReleaseDate::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
    'Hajime Fujimoto' => '藤本　壱',
    'Auto Update<br />Publish Date' => '公開日時の<br />自動変更',
    'Auto Update When Published' => '公開時に日時を自動変更',
    'Use Current Date' => '現在日時に変更',
    'Auto update publish date of page when page is published' => 'ウェブページの公開時に日時を自動変更する',
    'Website [_1]' => 'ウェブサイト「[_1]」',
    'Run setting of blog \'[_1]\'' => 'ブログ「[_1]」の設定',
    'Run setting of website \'[_1]\'' => 'ウェブサイト「[_1]」の設定',
    'Setting of ReleaseDate plugin' => 'ReleaseDateプラグインの設定',
    'To run setting, click below link.' => '設定は、以下のリンクをクリックして、個々のウェブサイト／ブログの設定ページで行ってください。',
);

if (MT->version_number >= 6) {
    $Lexicon{'Auto update publish date of entry / page.'} = '記事／ウェブページの公開日時を自動変更します。';
    $Lexicon{'Auto update publish date of entry when entry is published'} = '記事の公開時に日時を自動変更する';
}
else {
    $Lexicon{'Auto update publish date of entry / page.'} = 'ブログ記事／ウェブページの公開日時を自動変更します。';
    $Lexicon{'Auto update publish date of entry when entry is published'} = 'ブログ記事の公開時に日時を自動変更する';
}

1;
