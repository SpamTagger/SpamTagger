<?php
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 *
 * Slave servers table
 */

class Default_Model_DbTable_Slave extends Zend_Db_Table_Abstract {
  protected $_name = 'replica';

  public function __construct() {
  	$this->_db = Zend_Registry::get('writedb');
  }
}
