<?php $this->extend('_templates/default-nav'); ?>

<div class="tbl-ctrls">
	<?=form_open($form_url)?>
		<div class="app-notice-wrap"><?=ee('CP/Alert')->getAllInlines()?></div>

		<div class="title-bar js-filters-collapsible">
			<h2 class="title-bar__title"><?=$cp_heading?></h2>
			<?php if (isset($filters)) echo $filters; ?>
		</div>

		<?php $this->embed('_shared/thumb', $files->asArray()); ?>
		<?=$pagination?>
		<?php if ( ! empty($table['columns']) && ! empty($table['data'])): ?>
			<?php
				$options = [
					[
						'value' => "",
						'text' => '-- ' . lang('with_selected') . ' --'
					]
				];
				if (ee('Permission')->can('delete_files')) {
					$options[] = [
						'value' => "remove",
						'text' => lang('delete'),
						'attrs' => ' data-confirm-trigger="selected" rel="modal-confirm-delete-file"'
					];
				}
				$options[] = [
					'value' => "download",
					'text' => lang('download')
				];
				$this->embed('ee:_shared/form/bulk-action-bar', [
					'options' => $options,
					'modal' => true
				]);
			?>
		<?php endif; ?>
	<?=form_close()?>
</div>

<?php $this->embed('files/_delete_modal'); ?>
