<?php
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 *
 * Web interface configuration table
 */

class Default_Model_DbTable_UserGUI extends Zend_Db_Table_Abstract {
  protected $_name = 'user_gui';
  protected $_primary = 'set_id';

  public function __construct() {
  	$this->_db = Zend_Registry::get('writedb');
  }
}
