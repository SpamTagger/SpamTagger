<?php
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 *
 * Commtouch internal table
 */

class Default_Model_Antispam_DbTable_MessageSniffer extends Zend_Db_Table_Abstract {
  protected $_name = 'MessageSniffer';
  protected $_primary = 'set_id';

  public function __construct() {
  	$this->_db = Zend_Registry::get('writedb');
  }
}
