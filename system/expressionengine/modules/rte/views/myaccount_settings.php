<h3><?=$cp_page_title?></h3>

<p>
	<span><?=lang('enable_rte_myaccount')?></span>
	<?=form_radio('rte_enabled', 'y', ($rte_enabled=='y'), 'id="enable_rte_myaccount_y"')?> <?=lang('yes').NBS.NBS.NBS.NBS.NBS ?>
	<?=form_radio('rte_enabled', 'n', ($rte_enabled=='n'), 'id="enable_rte_myaccount_n"')?> <?=lang('no')?>
</p>
<p>
	<label for="rte_toolset_id"><?=lang('toolset')?></label>
	<?=form_dropdown('rte_toolset_id', $rte_toolset_id_opts, $rte_toolset_id, 'id="rte_toolset_id"').NBS ?>
	<input type="button" id="edit_toolset" class="submit js_hide" value="<?=lang('edit')?>"/>
</p>

<p class="submit"><?=form_submit('myaccount_settings_update', lang('update'), 'class="submit"')?></p>