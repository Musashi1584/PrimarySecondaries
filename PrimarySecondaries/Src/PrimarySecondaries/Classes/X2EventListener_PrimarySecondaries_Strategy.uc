class X2EventListener_PrimarySecondaries_Strategy extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateItemConstructionCompletedListenerTemplate());
	Templates.AddItem(CreateItemChangedListenerTemplate());

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
	// `LOG(default.class @ GetFuncName() @ XComGameState_Item(EventData).GetMyTemplateName(),, 'PrimarySecondaries');
	// class'X2DownloadableContentInfo_PrimarySecondaries'.static.UpdateStorageForItem(XComGameState_Item(EventData).GetMyTemplate(), true);
	return ELR_NoInterrupt;
}

static function CHEventListenerTemplate CreateItemChangedListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'PrimarySecondariesItemChangedListener');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('AddItemToHQInventory', OnAddItemToHQInventory, ELD_Immediate);
	`LOG("Register Event AddItemToHQInventory",, 'PrimarySecondaries');
	Template.AddCHEvent('RemoveItemFromHQInventory', OnRemoveItemFromHQInventory, ELD_Immediate);
	`LOG("Register Event RemoveItemFromHQInventory",, 'PrimarySecondaries');

	return Template;
}

static function EventListenerReturn OnAddItemToHQInventory(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Item ItemState;

	ItemState = XComGameState_Item(EventSource);

	`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ ItemState.Quantity,, 'PrimarySecondaries');
	
	return ELR_NoInterrupt;
}

static function EventListenerReturn OnRemoveItemFromHQInventory(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Item ItemState;

	ItemState = XComGameState_Item(EventSource);

	`LOG(GetFuncName() @ ItemState.GetMyTemplateName() @ ItemState.Quantity,, 'PrimarySecondaries');
	
	return ELR_NoInterrupt;
}