---@diagnostic disable-next-line: redefined-type
export type self = self;

export type Callback = (...any) -> ();

export type SignalClass = {
	new: () -> SignalObject,
};

export type SignalObject = {
	Connect: (self, Callback: Callback) ->  SignalConnection,
	Once: (self, Callback: Callback) ->  SignalConnection,
	Wait: (self, Callback: Callback) -> (...any),
	Fire: (self, ...any) -> (),
	DisconnectAll: (self) -> ()
};

export type SignalConnection = {
	Disconnect: (self) -> ()
};

export type Events = {
	CharacterAdded: SignalObject,
	CharacterRemoved: SignalObject,

	Walking: SignalObject,
	Jumping: SignalObject,
	FreeFalling: SignalObject
};

return {};