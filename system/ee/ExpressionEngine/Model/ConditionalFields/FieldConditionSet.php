<?php
/**
 * This source file is part of the open source project
 * ExpressionEngine (https://expressionengine.com)
 *
 * @link      https://expressionengine.com/
 * @copyright Copyright (c) 2003-2021, Packet Tide, LLC (https://www.packettide.com)
 * @license   https://expressionengine.com/license Licensed under Apache License, Version 2.0
 */

namespace ExpressionEngine\Model\ConditionalFields;

use ExpressionEngine\Service\Model\Model;

/**
 * Condition Set model
 */
class FieldConditionSet extends Model
{

    protected static $_primary_key = 'condition_set_id';
    protected static $_table_name = 'field_condition_sets';

    protected static $_validation_rules = array(
        'match' => 'enum[all,any]',
        'order' => 'integer'
    );

    protected $condition_set_id;
    protected $match; //'all' or 'any'
    protected $order;

    protected static $_relationships = array(
        'FieldConditions' => array(
            'model'      => 'FieldCondition',
            'type'       => 'hasMany'
        ),
        'ChannelFields' => array(
            'type' => 'hasAndBelongsToMany',
            'model' => 'ChannelField',
            'pivot' => array(
                'table' => 'field_condition_sets_channel_fields'
            )
        )
    );
}
