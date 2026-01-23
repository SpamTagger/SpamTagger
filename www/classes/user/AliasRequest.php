<?
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author Olivier Diserens
 * @copyright 2025, SpamTagger
 */

/**
 * This class takes care of alias adding requests
 */
class AliasRequest {

/**
 * Generate the alias request
 * Will store the request in the database and generate the mail message
 * @param  $alias  string    alias requested
 * @return         string    html status string
 */
public function requestForm($alias) {

  require_once('objects.php');

  global $lang_;
  global $user_;
  global $sysconf_;
  if (! $user_ instanceof User) {
    return "";
  }

  $alias = strtolower($alias);
  //check address format and domain validity
  $matches = array();
  if (! preg_match('/[a-zA-Z0-9_\-.]+\@([a-zA-Z0-9_\-.]+)/', $alias, $matches)) {
    return 'BADADDRESSFORMAT';
  }
  if (! in_array($matches[1], $sysconf_->getFilteredDomains())) {
    return 'NOTFILTEREDDOMAIN';
  }

  //check if address is already registered
  require_once('helpers/DataManager.php');
  $db_replicaconf = DM_SlaveConfig :: getInstance();
  $alias = $db_replicaconf->sanitize($alias);
  $query = "SELECT address FROM email where address='$alias' and user!=0";
  $res = $db_replicaconf->getHash($query);
  if (is_array($res) && isset($res['address']) && $res['address'] == $alias) {
    return 'ALIASALREADYREGISTERD';
  }

  //check if no previous request are pending for this address

  // first delete old records
  $query = "DELETE FROM pending_alias WHERE date_in != CURDATE();";
  $db_replicaconf->doExecute($query);

  // and the check if still pending requests exists
  $query = "SELECT alias FROM pending_alias WHERE alias='$alias'";
  $res = $db_replicaconf->getHash($query);
  if (is_array($res) && isset($res['alias']) &&  $res['alias'] == $alias) {
    return 'ALIASALREADYPENDING';
  }

  // save user if not registered, so that alias request can have a user reference
  if (!$user_->isRegistered()) {
    $user_->save();
  }

  // generate unique id
  $token = md5 (uniqid (rand()));
  $query = "INSERT INTO pending_alias SET id='$token', date_in=NOW(), alias='$alias', user='".$user_->getID()."'";
  $db_replicaconf->doExecute($query);

  $sysconf_ = SystemConfig::getInstance();

  // create the command string
  $command = $sysconf_->SRCDIR_."/bin/send_aliasrequest.pl ".$user_->getPref('username')." ".$alias." ".$token." ".$lang_->getLanguage();
  $command = escapeshellcmd($command);
  // and launch
  $result = `$command`;
  $result = trim($result);

  $tmp = array();
  if (preg_match('/REQUESTSENT (\S+\@\S+)/', $result, $tmp)) {
    return 'ALIASPENDING';
  }
  return  $result;
}

  /**
   * This will check the request and add the alias if correct
   * @param  $id   string  MD5 hash of unique id
   * @param  $alias  string  alias requested
   * @return       string    html status string
   */
  public function addAlias($id, $alias) {
    if (!is_string($id)) {
      return false;
    }
    require_once('helpers/DataManager.php');
    $db_replicaconf = DM_SlaveConfig :: getInstance();
    $alias = $db_replicaconf->sanitize($alias);
    $id = $db_replicaconf->sanitize($id);
    $lang_ = Language::getInstance('user');

    // check if pending alias exists and id is correct
    $query = "SELECT a.user, u.username, u.id, u.domain FROM pending_alias a, user u WHERE a.id='$id' AND a.alias='$alias' AND a.user=u.id";
    $res = $db_replicaconf->getHash($query);

    if (!is_array($res) || ! isset($res['username'])) {
      return 'ALIASNOTPENDING';
    }

    // ok, so we create the user instance
    require_once("user/User.php");
    $user_ = new User();
    $user_->setDomain($res['domain']);
    $user_->load($res['username']);

    // and we delete the pending request
    $query = "DELETE FROM pending_alias WHERE id='$id' AND alias='$alias'";
    $db_replicaconf->doExecute($query);

    // finally, we add the address to the user
    //@todo check return codes
    $user_->addAddress($alias);
    $user_->save();

    return 'ALIASADDED';
  }

  /**
   * This will check the request and remove the request if correct
   * @param  $id   string  MD5 hash of unique id
   * @param  $alias  string  alias requested
   * @return       string  html status string
   */
  public function remAlias($id, $alias) {
    if (!is_string($id)) {
      return false;
    }
    require_once('helpers/DataManager.php');
    $db_replicaconf = DM_SlaveConfig :: getInstance();
    $alias = $db_replicaconf->sanitize($alias);
    $id = $db_replicaconf->sanitize($id);
    $lang_ = Language::getInstance('user');

    // check if pending alias exists and id is correct
    $query = "SELECT a.user, u.username, u.id, u.domain FROM pending_alias a, user u WHERE a.id='$id' AND a.alias='$alias' AND a.user=u.id";
    $res = $db_replicaconf->getHash($query);

    if (!is_array($res)) {
      return "<font color=\"red\">".$lang_->print_txt('ALIASNOTPENDING')."</font><br/><br/>";
    }

    $query = "DELETE FROM pending_alias WHERE id='$id' AND alias='$alias'";
    $db_replicaconf->doExecute($query);

    return 'ALIASREQUESTREMOVED';
  }

  public function remAliasWithoutID($alias) {
    if (!is_string($alias)) {
      return false;
    }
    require_once('helpers/DataManager.php');
    $db_replicaconf = DM_SlaveConfig :: getInstance();
    $alias = $db_replicaconf->sanitize($alias);

    $query = "DELETE FROM pending_alias WHERE alias='$alias'";
    $db_replicaconf->doExecute($query);
    return 'ALIASREQUESTREMOVED';
  }

}

?>
