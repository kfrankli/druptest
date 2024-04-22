<?php

/**
 * @file
 * Enables modules and site configuration for a smithsonian site installation.
 */

use Drupal\Core\Form\FormStateInterface;
use Symfony\Component\Yaml\Yaml;
use Drupal\Core\Config\InstallStorage;

/**
 * Implements hook_form_FORM_ID_alter() for install_configure_form().
 *
 * Allows the profile to alter the site configuration form.
 */
function smithsonian_form_install_configure_form_alter(&$form, FormStateInterface $form_state) {
//  $form['site_information']['site_name']['#default_value'] = 'Umami Food Magazine';
  $form['site_information']['site_mail']['#default_value'] = 'OCIO_Web_Admin@si.edu';
  $form['admin_account']['account']['mail']['#default_value'] = 'OCIO_Web_Admin@si.edu';
  $form['admin_account']['account']['name']['#default_value'] = 'sysadmin';
  $form['regional_settings']['site_default_country']['#default_value'] = 'US';
  $form['update_notifications']['enable_update_status_emails']['#default_value'] = 0;
}

function hook_modules_installed($modules, $is_syncing) {
  if (in_array('ldap_servers', $modules)) {
    smithsonian_ldap_settings();
  }

}

function smithsonian_ldap_settings() {
  $txt_file    = file_get_contents('../../ldap.txt');
  $rows        = explode("\n", $txt_file);
  $config_install_path = \Drupal::service('extension.list.profile')->getPath('smithsonian') . '/' . InstallStorage::CONFIG_OPTIONAL_DIRECTORY;
  if (is_dir($config_install_path)) {
    // scan directory for config.
    $settings_config_files = \Drupal::service('file_system')
      ->scanDirectory($config_install_path, '/^ldap_servers.server.si_usdc01.yml$/i');
    // \Drupal::service('config.factory')->getEditable('example.settings');
    if (isset($settings_config_files) && is_array($settings_config_files)) {
      foreach ($settings_config_files as $settings_config_file) {
        $settings_config_file_content = file_get_contents(DRUPAL_ROOT . '/' . $settings_config_file->uri);
        $settings_config_file_data = (array) Yaml::parse($settings_config_file_content);
        $config = \Drupal::service('config.factory')->getEditable($settings_config_file->name);
        $config->setData($settings_config_file_data);
        $config->set('binddn', $rows[0]);
        $config->set('bindpw', $rows[1]);
        $config->save();
      }
    }
  }
}

function smithsonian_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  if (isset($form['field_hero_type'])) {
    if (isset($form['field_show_title'])) {
      $form['field_show_title']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 1],
            ['value' => 2]
          ],
        ],
      ];
    }
    if (isset($form['field_hero_image'])) {
      $form['field_hero_image']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 0],
          ],
        ],
        'required' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 0],
          ],
        ],
      ];
    }
    if (isset($form['field_bg_image'])) {
      $form['field_hero_image']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 0],
          ],
        ],
        'required' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 0],
          ],
        ],
      ];
    }
    if (isset($form['field_bg_image_type'])) {
      $form['field_bg_image_type']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 0],
          ],
        ],
      ];
    }
    if (isset($form['field_rotate_tiles'])) {
      $form['field_rotate_tiles']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 2],
          ],
        ],
        'required' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 2],
          ],
        ],
      ];
    }
    if (isset($form['field_tiles'])) {
      $form['field_tiles']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 2],
          ],
        ],
        'required' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 2],
          ],
        ],
      ];
    }
    if (isset($form['field_slideshow'])) {
      $form['field_slideshow']['#states'] = [
        'visible' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 1],
          ],
        ],
        'required' => [
          ':input[name="field_hero_type"]' => [
            ['value' => 1],
          ],
        ],
      ];
    }
    //$form['#attached']['library'][] = 'smithsonian/form';
    $form['#validate'][] = 'smithsonian_entity_form_validate';
  }
}


function smithsonian_entity_form_validate($form, FormStateInterface $form_state) {
  if ($form_state->getValue('form_id') !== 'conditional_field_edit_form_tab' && $form_state->getValue('field_hero_type')) {
    switch ($form_state->getValue('field_hero_type')[0]['value']) {
      case 0:
        if (isset($form['field_hero_image']) && empty($form_state->getValue('field_hero_image')['target_id'])) {
          $form_state->setErrorByName('field_hero_image', t('Please add a hero image'));
        }
        elseif (isset($form['field_bg_image']) && empty($form_state->getValue('field_bg_image')['target_id'])) {
          $form_state->setErrorByName('field_bg_image', t('Please add a hero image'));
        }
        break;
      case 1:
        if (isset($form['field_slideshow'])) {
          $slides = $form_state->getValue('field_slideshow');
          if (isset($slides['add_more'])) unset($slides['add_more']);
          if (empty($slides)) {
            $form_state->setErrorByName('field_hero_type', t('Please add slides for the slideshow'));
          }
        }

        break;
      case 2:
        if (isset($form['field_tiles'])) {
          $tiles = $form_state->getValue('field_tiles');
          if (isset($tiles['add_more'])) unset($tiles['add_more']);
          if (empty($tiles)) {
            $form_state->setErrorByName('field_hero_type', t('Please add tiles for the tile layout'));
          }
        }
        break;
    }
  }
}

function smithsonian_entity_view_mode_alter(&$view_mode, \Drupal\Core\Entity\EntityInterface $entity) {
  if ( $entity->getEntityTypeId() === 'media' && isset($entity->_referringItem)) {
    $refEntity = $entity->_referringItem->getEntity();
    if (isset($refEntity->field_bg_image_type)) {
      $view_mode = $refEntity->field_bg_image_type->value == 1 ? 'hero_full' : ($refEntity->field_bg_image_type->value == 2 ? 'hero_side' : $view_mode);
    }
  }
}
