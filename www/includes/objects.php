<?
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author Olivier Diserens
 * @copyright 2025, SpamTagger
 */

 /**
 * include log, system config and session objects
 */
require_once('variables.php');
require_once('system/SystemConfig.php');
require_once('user/User.php');
require_once('view/Language.php');

ini_set('arg_separator.output', '&amp;');

/**
 * session objects
 */
global $sysconf_;
global $lang_;
global $log_;

// set log and load SystemConfig singleton
$log_->setIdent('user');
$sysconf_ = SystemConfig::getInstance();

//check user is logged. Redirect if not
if (!isset($_SESSION['user'])) {
  $location = 'login.php';
  if (isset($_REQUEST['d']) && preg_match('/^[0-9a-f]{32}(?:[0-9a-f]{8})?$/i', $_REQUEST['d'])) {
    $location .= "?d=".$_REQUEST['d'];
  }
  if (isset($_REQUEST['p'])) {
    $location .= '&p='.$_REQUEST['p'];
  }
  header("Location: ".$location);
  exit;
} else {
  $user_ = unserialize($_SESSION['user']);
}
$lang_ = Language::getInstance('user');

// delete user session object
function unregisterAll() {
  unset($_SESSION['user']);
  unset($_SESSION['domain']);
}
?>
