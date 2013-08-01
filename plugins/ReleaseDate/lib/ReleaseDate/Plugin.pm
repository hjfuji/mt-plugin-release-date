package ReleaseDate::Plugin;
use strict;

require MT;
require MT::PluginData;
require MT::Request;
require MT::Entry;
require MT::Website;
require MT::Blog;

sub init_app {
    my $app = shift;
    my $plugin = MT->component('ReleaseDate');
    bless $plugin, 'MT::Plugin::ReleaseDate';
}

# customize edit template
sub add_checkbox {
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = MT->component('ReleaseDate');

    return if ($app->mode ne 'view' ||
               $app->param('_type') ne 'entry' &&
               $app->param('_type') ne 'page');

    my $entry_id = $app->param('id') || 0;
    my $blog_id = $app->param('blog_id');
    my $reldate_ischeck;
    if ($app->param('_type') eq 'entry') {
        $reldate_ischeck = $plugin->get_config_value('reldate_ischeck', 'blog:' . $blog_id);
    }
    elsif ($app->param('_type') eq 'page') {
        $reldate_ischeck = $plugin->get_config_value('reldate_ischeck_page', 'blog:' . $blog_id);
    }

    # if entry is not new or is not hold, don't add checkbox
    if ($entry_id) {
        my $entry = MT::Entry->load($entry_id);
        if ($entry->status != MT::Entry::HOLD()) {
            return;
        }
    }

    # load check status from plugin_data
    my $plugin_data = MT::PluginData->load({ plugin => $plugin->name,
                                             key => $blog_id });
    if (!$plugin_data) {
        $plugin_data = MT::PluginData->new();
        $plugin_data->plugin($plugin->name);
	$plugin_data->key($blog_id);
    }
    my $checked_hash = $plugin_data->data() || {};
    my $checked_str;
    if ($app->param('reedit')) {
        $checked_str = " checked=\"checked\""
            if ($app->param('update_release_date'));
    }
    else {
        $checked_str = " checked=\"checked\""
            if (($reldate_ischeck && !defined($checked_hash->{$entry_id}))
                || $checked_hash->{$entry_id} == 1);
    }

    my $btn_label = $plugin->translate("Use Current Date");
    my $chk_label = $plugin->translate("Auto Update When Published");
    my $node = $tmpl->createElement('app:setting');
    $node->setAttribute('id', 'update_release_date');
    $node->setAttribute('label', $plugin->translate('Auto Update<br />Publish Date'));
    $node->setAttribute('label_class', 'top-label');
    my $innerHTML = <<HERE;
<span>
    <input type="checkbox" name="update_release_date" id="update_release_date" value="1"$checked_str> $chk_label
<span><br />
<span>
    <input name="update_now_date" id="update_now_date" type="button" value="$btn_label" onclick="FJReleaseDate.updateNow();" />
</span>

<script type="text/javascript">
<!--
var FJReleaseDate = {
    updateNow : function() {
        var dt = new Date();
        var y = dt.getFullYear();
        var m = FJReleaseDate.getLastTwoChar(dt.getMonth() + 1);
        var d = FJReleaseDate.getLastTwoChar(dt.getDate());
        var h = FJReleaseDate.getLastTwoChar(dt.getHours());
        var mn = FJReleaseDate.getLastTwoChar(dt.getMinutes());
        var s = FJReleaseDate.getLastTwoChar(dt.getSeconds());
        document.entry_form.authored_on_date.value = y + "-" + m + "-" + d;
        document.entry_form.authored_on_time.value = h + ":" + mn + ":" + s;
        document.entry_form.update_release_date.checked = false;
    },

    getLastTwoChar : function(str) {
        str = "00" + str;
        return str.substring(str.length - 2);
    }
};
-->
</script>

HERE
    $node->innerHTML($innerHTML);
    my $host_node = $tmpl->getElementById('authored_on');
    if ($host_node) {
        $tmpl->insertAfter($node, $host_node);
    }
}

# customize preview template
sub add_checkbox_preview {
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = MT->component('ReleaseDate');

    my $checked = $app->param('update_release_date');

    my $js = <<HERE;
<script type="text/javascript">
//<![CDATA[
TC.attachLoadEvent(function(){
    try {
        var ctlDivElm = document.getElementById('entry-preview-control-strip');
        var frmElm = ctlDivElm.getElementsByTagName('form')[0];
        var hidElm = document.createElement('input');
        hidElm.type = 'hidden';
        hidElm.id = 'update_release_date';
        hidElm.name = 'update_release_date';
        hidElm.value = '$checked';
        frmElm.appendChild(hidElm);
    }
    catch(e) {
    }
});
//]]>
</script>

HERE
    $param->{js_include} .= $js;
}

# releasedate main
sub releasedate {
    my ($eh, $app, $entry, $org_entry) = @_;
    my $plugin = MT->component('ReleaseDate');
    my $ischangedate = 0;
    my $oldentry;

    # save hold status to cache
    my $req = MT::Request->instance;
    my $is_hold = 1;
    if ($entry->exists) {
        $is_hold = ($org_entry->status == MT::Entry::HOLD());
    }
    $req->cache('ReleaseDate Temp ' . $entry->id, $is_hold);

    # get value of update release date checkbox
    my $checked = $app->param('update_release_date');
    return 1 if (!$checked);

    # if entry is new
    if (!$entry->exists) {
        # if entry is to release
        if ($entry->status == MT::Entry::RELEASE()) {
            # set flag of changing date
            $ischangedate = 1;
        }
    }
    # if entry exists
    else {
        # if status is changed from hold to release
        if ($entry->status == MT::Entry::RELEASE() &&
            $org_entry->status == MT::Entry::HOLD()) {
            $ischangedate = 1;
        }
    }

    # if flag($ischangedate) is true and checkbox is on
    if ($ischangedate) {
        # change authored_on to released date
        my ($sec, $min, $hour, $day, $mon, $year) = localtime;
        my $released_on = sprintf("%04d%02d%02d%02d%02d%02d", 
            $year + 1900, $mon + 1, $day, $hour, $min, $sec);
        $entry->authored_on($released_on);
    }

    return 1;
}

# update hash
sub update_hash {
    my ($eh, $app, $entry) = @_;
    my $plugin = MT->component('ReleaseDate');
    my $checked;

    # load check status from plugin_data
    my $plugin_data = MT::PluginData->load({ plugin => $plugin->name,
                                             key => $entry->blog_id });
    if (!$plugin_data) {
        $plugin_data = MT::PluginData->new();
        $plugin_data->plugin($plugin->name);
	$plugin_data->key($entry->blog_id);
    }
    my $checked_hash = $plugin_data->data() || {};

    # load hold status from cache
    my $req = MT::Request->instance;
    my $is_hold = $req->cache('ReleaseDate Temp ' . $entry->id);
    $req->cache('ReleaseDate Temp ' . $entry->id, undef);

    # if entry status is hold
    if ($entry->status == MT::Entry::HOLD() && $is_hold) {
        # save checkbox status
            $checked = $app->param('update_release_date') || 0;
            $checked_hash->{$entry->id} = $checked;
    }
    # if entry status is not hold
    else {
        # delete status information from hash
        delete $checked_hash->{$entry->id};
    }

    # save plugin_data
    $plugin_data->data($checked_hash);
    $plugin_data->save or die $plugin->errstr;

    1;
}

package MT::Plugin::ReleaseDate;

use base qw( MT::Plugin );

sub load_config {
    my ($plugin, $param, $scope) = @_;

    $plugin->SUPER::load_config($param, $scope);
    if ($scope eq 'system') {
        my @data;
        my @websites = MT->model('website')->load;
        for my $website (@websites) {
            my @blogs = MT->model('blog')->load({ parent_id => $website->id });
            my @blog_data = map {
                {
                    blog_name => $_->name,
                    blog_id => $_->id,
                }
            } @blogs;
            push @data, {
                website_name => $website->name,
                website_id => $website->id,
                blogs => \@blog_data,
            };
        }
        $param->{fj_reldate_websites} = \@data;
    }
    else {
        my $app = MT->instance;
        my $blog = $app->blog;
        if ($blog->class eq 'blog' || MT->version_number >= '6') {
            $param->{fj_reldate_blog} = 1;
        }
    }
}

1;
