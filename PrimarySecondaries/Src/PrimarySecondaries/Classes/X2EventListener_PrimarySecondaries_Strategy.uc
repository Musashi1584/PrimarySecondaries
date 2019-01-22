class X2EventListener_PrimarySecondaries_Strategy extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateItemConstructionCompletedListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateItemConstructionCompletedListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'PrimarySecondariesItemConstructionCompleted');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('ItemConstructionCompleted', OnItemConstructionCompleted, ELD_OnStateSubmitted);
	`LOG("Register Event ItemConstructionCompleted",, 'PrimarySecondaries');

	return Template;
}

static function EventListenerReturn OnItemConstructionCompleted(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	`LOG(default.class @ GetFuncName() @ XComGameState_Item(EventData).GetMyTemplateName(),, 'PrimarySecondaries');
	class'X2DownloadableContentInfo_PrimarySecondaries'.static.UpdateStorageForItem(XComGameState_Item(EventData).GetMyTemplate(), true);
	return ELR_NoInterrupt;
}
