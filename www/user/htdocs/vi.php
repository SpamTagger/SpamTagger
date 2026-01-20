<?
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author Olivier Diserens
 * @copyright 2025, SpamTagger
 *
 * This is the controller for the reasons list display page
 */

if ($_SERVER["REQUEST_METHOD"] == "HEAD") {
  return 200;
}

require_once('variables.php');
require_once("view/Language.php");
require_once("user/Spam.php");
require_once("view/Template.php");

$sysconf = SystemConfig::getInstance();
$viewrules = 0;
$viewbody = 0;
$viewheaders = 0;
$firstopen = 1;

## check params
if (!isset($_GET['id']) || !isset($_GET['a'])) {
  die ("BADPARAMS");
}

if (isset($_GET['vr']) || isset($_GET['vh']) || isset($_GET['vb'])) {
  $firstopen = 0;
}
$spam = new Spam();
if (! $spam->loadDatas($_GET['id'], $_GET['a'])) {
  die ("CANNOTLOADMESSAGE");
}

if (isset($_GET['vr']) && $_GET['vr'] == 1) {
  $viewrules = 1;
}
if (isset($_GET['vh']) && $_GET['vh'] == 1) {
  $viewheaders = 1;
}
if (isset($_GET['vb']) && $_GET['vb'] == 1) {
  $viewbody = 1;
}

if (! $spam->loadHeadersAndBody()) {
  die ("CANNOTLOAD HEADERSANDBODY");
}

// create view
$template_ = new Template('vi.tmpl');
if ($spam->getData('M_score') == "NULL")
  $template_->setCondition('SCORENOTNULL', 0);
else {
  $template_->setCondition('SCORENOTNULL', 1);
}
if ($viewrules) {
  $template_->setCondition('VIEWSCORE', 1);
} else {
  $template_->setCondition('VIEWSCORE', 0);
}
$template_->setCondition('FIRSTOPEN', $firstopen);

// prepare replacements
$replace = array(
   '__MSG_ID__' => $spam->getData('exim_id'),
   '__TO__' => addslashes($spam->getCleanData('to')),
   '__TOTAL_SCORE__' => htmlentities(displayHit($spam->getData('M_score'))),
   '__NEWS__' => $spam->getData('is_newsletter'),
   '__STOREREPLICA__' => $spam->getData('store_replica'),
);

$replace = $spam->setReplacements($template_, $replace);
//display page
$template_->output($replace);

function displayHit($value) {
  global $lang_;
  if ($value == "" || $value== "0.000") {
  	return $lang_->print_txt('NONE');
  }
  if (! is_numeric($value) ) {
      return $value;
  }
  return number_format($value, 1, '.', '');
}

?>
