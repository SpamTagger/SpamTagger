<?
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 */


/**
 * This class takes care of storing settings of a simple server
 * @package SpamTagger
 */
 class SimpleServerSettings extends ConnectorSettings {

   /**
    * template tag
    * @var string
    */
   protected $template_tag_ = 'SIMPLEAUTH';

    /**
   * Specialized settings array with default values
   * @var array
   */
   protected $spec_settings_ = array(
                              'usessl' => false
                             );
   /**
    * fields type
    * @var array
    */
   protected $spec_settings_type_ = array(
                               'usessl' => array('checkbox', '1')
                               );

 }
?>
