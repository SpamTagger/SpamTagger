<?php
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 *
 * Pending alias requests table
 */

class Default_Model_DbTable_RRDGraphic extends Zend_Db_Table_Abstract {
  protected $_name = 'rrd_stats';

  public function __construct() {
  	$this->_db = Zend_Registry::get('writedb');
  }
}
