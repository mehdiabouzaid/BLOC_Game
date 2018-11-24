unit Media_sdl;
interface
uses sdl, sdl_ttf, sysutils, SDL_MIXER;
const
	AUDIO_FREQUENCY : Integer = 22050;
	AUDIO_FORMAT : WORD = AUDIO_S16;
	AUDIO_CHANNELS : Integer = 2;
	AUDIO_CHUNKSIZE : Integer = 4096;

procedure ecrire(p_screen : PSDL_Surface; txt : String; x, y, taille : Integer);
procedure lancerMusique(musique : string);

implementation


	procedure ecrire(p_screen : PSDL_Surface; txt : String; x, y, taille : Integer);
	{Procédure nous permettant d'écrire à l'écran (scores, pseudos des joueurs par exemple)}
	var position : TSDL_Rect;
		police : pTTF_Font;
		couleur : PSDL_Color;
		texte : PSDL_Surface;
		ptxt : pChar;
	Begin
		(*Chargement de la bibliothèque*)
		if TTF_INIT = -1 then HALT;

		(*Chargement de la police et choix de la couleur*)
		police := TTF_OPENFONT('Pacifico.ttf', taille);
		new(couleur);
		couleur^.r := 94; couleur^.g := 0; couleur^.b := 0; 
		
		(*Transformation du String en PChar*)
		ptxt := StrAlloc(length(txt) + 1); 
		StrPCopy(ptxt, txt);
		
		(*Création de la texture*)
		texte := TTF_RENDERTEXT_BLENDED(police, ptxt, couleur^);
		position.x := x; 
		position.y := y;	

		(*Affichage à l'écran du texte*)
		SDL_BlitSurface(texte, NIL, p_screen, @position);

		(*Libération de la mémoire*)
		dispose(couleur); 
		strDispose(ptxt);
		TTF_CloseFont(police);
		TTF_Quit();
		SDL_FreeSurface(texte);
	end;


	procedure lancerMusique(musique : string);
	{Procédure de mise en musique}
	var sound : pMIX_MUSIC = NIL;
		pmusique : pChar;
	begin
		(*Chargement de la bibliothèque*)
		if MIX_OpenAudio(AUDIO_FREQUENCY, AUDIO_FORMAT, AUDIO_CHANNELS, AUDIO_CHUNKSIZE) <> 0 then HALT;
			
		(*Chargement du fichier mp3 après avoir transformé le string en PCHar*)
		pmusique := StrAlloc(length(musique) + 1);
		StrPCopy(pmusique, musique); 
		sound := MIX_LOADMUS(pmusique);
		
		(*Choix du volume et lancement de la musique*)
		MIX_VolumeMusic(MIX_MAX_VOLUME);
		MIX_PlayMusic(sound, -1);
	end;
end.
