<?php
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 *
 * Filetype table
 */

class Default_Model_DbTable_FileType extends Zend_Db_Table_Abstract {
  protected $_name = 'filetype';

  public function __construct() {
  	$this->_db = Zend_Registry::get('writedb');
  }
}
