<?php
/**
 * @license https://www.gnu.org/licenses/gpl-3.0.en.html
 * @package SpamTagger
 * @author John Mertz
 * @copyright 2026, SpamTagger
 *
 * controller for cluster configuration
 */

class ClusterController extends Zend_Controller_Action
{
  public function init()
  {
    $layout = Zend_Layout::getMvcInstance();
    $view=$layout->getView();
    $view->headLink()->appendStylesheet($view->css_path.'/main.css');
    $view->headLink()->appendStylesheet($view->css_path.'/navigation.css');

    $main_menus = Zend_Registry::get('main_menu')->findOneBy('id', 'Configuration')->class = 'menuselected';
    $view->selectedMenu = 'Configuration';
    $main_menus = Zend_Registry::get('main_menu')->findOneBy('id', 'subconfig_Cluster')->class = 'submenuelselected';
    $view->selectedSubMenu = 'Cluster';
  }

  public function indexAction() {

  }

}
