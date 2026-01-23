<?
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 */


/**
 * This class takes care of reformatting the login passed by removing any domain eventually given.
 * @package SpamTagger
 */
class SimpleFormatter extends LoginFormatter {


     public function format($login_given, $domain_name) {
       $matches = array();
       if (preg_match('/^(\S+)[\@\%](\S+)$/', $login_given, $matches)) {
        return $matches[1];
       }
       return $login_given;
     }
}
?>
