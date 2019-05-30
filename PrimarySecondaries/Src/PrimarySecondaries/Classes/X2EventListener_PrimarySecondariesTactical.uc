class X2EventListener_PrimarySecondariesTactical extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	//Templates.AddItem(CreateListeners());

	return Templates;
}

static function X2EventListenerTemplate CreateListeners()
{
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'PSAbilityActivatedListener');
	//Template.AddEvent('AbilityActivated', OnAbilityActivated);
	//Template.RegisterInTactical = true;

	return Template;
}