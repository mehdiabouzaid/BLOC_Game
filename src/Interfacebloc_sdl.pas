unit Interfacebloc_sdl;
interface
uses sdl,sdl_image;
const
	MAX = 100;
	(*Largeur puis hauteur en pixels de la surface de jeu*)
	SURFACEWIDTH = 768; 
	SURFACEHEIGHT = 768;
	SPRITEW = 64; 
	SPRITEH = 64;
	(*Largeur puis hauteur en nombre de sprites de la surface de jeu*) 
	PLAYGROUNDW = 12;
	PLAYGROUNDH = 12; 
	
type
	Scenejeu = array[1..MAX, 1..MAX] of Integer;
	TOrientation = (droite, gauche);
	(*Enregistrement de la scène du personnage qui contiendra sa position et son orientation*)
    TScene = record 
        i, j : Integer; 
        orientation : TOrientation; 
    end;
    PScene = ^TScene; 
    
    (*TSpriteSheet est une feuille de textures qui contient toutes les textures du jeu*)
    TSpriteSheet = record 
		right_kirby, right_hulk, right_hulk_almost_dead, right_flash, right_batman, left_kirby, left_hulk, left_hulk_almost_dead, left_flash, left_batman, bloc, alerte, game_over, screen, carre_selection_perso : PSDL_Surface;
    end;
    PSpriteSheet = ^TSpriteSheet; 
    
    (*Enregistrement réalisé pour chaque joueur avec son pseudo et ses records*)
    Joueur = record 
		nom : string;
		best_kirby_score, best_batman_score, best_flash_score, best_hulk_score : Integer;
    end;
	Tab_joueurs = array[1..10000] of Joueur;


function newScene() : PScene;
function newSpriteSheet() : PSpriteSheet;
procedure libererMemoire(p_scene : PScene; p_sprite_sheet : PSpriteSheet);
procedure afficherEcranGameOver(var p_screen : PSDL_SURFACE; p_sprite_sheet : PSpriteSheet; score : longint);
procedure afficherEcranMenu(var p_screen : PSDL_SURFACE; p_sprite_sheet : PSpriteSheet; mort : boolean; score : longint);
procedure afficherAlertesBlocsPerso(p_screen : PSDL_Surface; p_sprite_sheet : PSpriteSheet; p_scene : PScene; perso : string; viesDeHulk : Integer; var tableau_jeu : Scenejeu);

implementation

	
	function newScene() : PScene;
	{Initialisation d'une scene}
	begin
		new(newScene);
		(*On place le personnage au milieu du bas de l'écran*)
		newScene^.i := round((PLAYGROUNDW) / 2); 
		newScene^.j := round(PLAYGROUNDH - 1);
		(*On charge l'image du personnage initialement orienté vers la droite*)
		newScene^.orientation := droite; 
	end;


	function newSpriteSheet() : PSpriteSheet;
	{Chargement en mémoire des textures}
	begin
		new(newSpriteSheet);
		newSpriteSheet^.bloc := IMG_Load('bloc.png');
		newSpriteSheet^.alerte := IMG_Load('alerte.png');
		newSpriteSheet^.right_kirby := IMG_Load('rightkirby.png');
		newSpriteSheet^.left_kirby := IMG_Load('leftkirby.png');
		newSpriteSheet^.right_hulk := IMG_Load('righthulk.png');
		newSpriteSheet^.left_hulk := IMG_Load('lefthulk.png');
		newSpriteSheet^.right_hulk_almost_dead := IMG_Load('righthulkalmostdead.png');
		newSpriteSheet^.left_hulk_almost_dead := IMG_Load('lefthulkalmostdead.png');
		newSpriteSheet^.right_flash := IMG_Load('rightflash.png');
		newSpriteSheet^.left_flash := IMG_Load('leftflash.png');
		newSpriteSheet^.right_batman := IMG_Load('rightbatman.png');
		newSpriteSheet^.left_batman := IMG_Load('leftbatman.png');
		newSpriteSheet^.screen := IMG_Load('screen.jpg');
		newSpriteSheet^.game_over := IMG_Load('gameover.png');
		newSpriteSheet^.carre_selection_perso := IMG_Load('carre_selection_perso.png');
	end;


	procedure libererMemoire(p_scene : PScene; p_sprite_sheet : PSpriteSheet);
	{Déchargement des textures}
	begin
		dispose(p_scene);
		SDL_FreeSurface(p_sprite_sheet^.bloc);
		SDL_FreeSurface(p_sprite_sheet^.alerte);
		SDL_FreeSurface(p_sprite_sheet^.right_kirby);
		SDL_FreeSurface(p_sprite_sheet^.left_kirby);
		SDL_FreeSurface(p_sprite_sheet^.right_hulk);
		SDL_FreeSurface(p_sprite_sheet^.left_hulk);
		SDL_FreeSurface(p_sprite_sheet^.right_flash);
		SDL_FreeSurface(p_sprite_sheet^.left_flash);
		SDL_FreeSurface(p_sprite_sheet^.right_batman);
		SDL_FreeSurface(p_sprite_sheet^.left_batman);
		SDL_FreeSurface(p_sprite_sheet^.screen);
		SDL_FreeSurface(p_sprite_sheet^.game_over);
		SDL_FreeSurface(p_sprite_sheet^.carre_selection_perso);
		dispose(p_sprite_sheet);
	end;

	
	procedure afficherEcranGameOver(var p_screen : PSDL_SURFACE; p_sprite_sheet : PSpriteSheet; score : longint);
	{Affichage de l'écran Game Over}
	var destination_rect : TSDL_RECT;
	begin
		destination_rect.x := 0;
		destination_rect.y := 0;
		destination_rect.w := 800;
		destination_rect.h := 800;
		SDL_BlitSurface(p_sprite_sheet^.game_over, NIL, p_screen, @destination_rect);
		SDL_Flip(p_screen);
	end;


	procedure afficherEcranMenu(var p_screen : PSDL_SURFACE; p_sprite_sheet : PSpriteSheet; mort : boolean; score : longint);
	{Affichage du menu avec les différents personnages}
	var destination_rect : TSDL_RECT;
	begin
		(*Affichage du fond*)
		destination_rect.x := 0;
		destination_rect.y := 0;
		destination_rect.w := SURFACEWIDTH;
		destination_rect.h := SURFACEHEIGHT;
		SDL_BlitSurface(p_sprite_sheet^.screen, NIL, p_screen, @destination_rect);
		(*Affichage de Kirby*)
		destination_rect.x := 175;
		destination_rect.y := 285;
		destination_rect.w := SPRITEW;
		destination_rect.h := SPRITEH;
		SDL_BlitSurface(p_sprite_sheet^.right_kirby, NIL, p_screen, @destination_rect);
		(*Affichage de Batman*)
		destination_rect.x := 338;
		destination_rect.y := 108;
		destination_rect.w := SPRITEW;
		destination_rect.h := SPRITEH;
		SDL_BlitSurface(p_sprite_sheet^.left_batman, NIL, p_screen, @destination_rect);
		(*Affichage de Hulk*)
		destination_rect.x := 300;
		destination_rect.y := 666;
		destination_rect.w := SPRITEW;
		destination_rect.h := SPRITEH;
		SDL_BlitSurface(p_sprite_sheet^.right_hulk, NIL, p_screen, @destination_rect);
		(*Affichage de Flash*)
		destination_rect.x := 600;
		destination_rect.y := 340;
		destination_rect.w := SPRITEW;
		destination_rect.h := SPRITEH;
		SDL_BlitSurface(p_sprite_sheet^.left_flash, NIL, p_screen, @destination_rect);
		SDL_Flip(p_screen);
	end;


	procedure afficherAlertesBlocsPerso(p_screen : PSDL_Surface; p_sprite_sheet : PSpriteSheet; p_scene : PScene; perso : string; viesDeHulk : Integer; var tableau_jeu : Scenejeu);
	{Affichage des images d'alerte, des blocs et du personnage à l'écran}
	var	i, j : Integer;
		destination_rect : TSDL_RECT;
		player_sprite : PSDL_Surface;
		
	begin
		(*Parcourt le tableau et affiche un point d'exclamation si la case du tableau vaut 3 ou un bloc si la case vaut 1 *)
		for i := PLAYGROUNDW downto 1 do 
		begin
			for j := PLAYGROUNDH downto 1 do
			begin
				if tableau_jeu[i][1] = 3 then
				begin
					(*Affichage des points d'exclamation*)
					destination_rect.x := (i - 1) * SPRITEW;
					destination_rect.y := 0;
					destination_rect.w := SPRITEW;
					destination_rect.h := SPRITEH;
					SDL_BlitSurface(p_sprite_sheet^.alerte, NIL, p_screen, @destination_rect);
				end;
				if tableau_jeu[i][j] = 1 then
				begin
					(*Affichage des blocs*)
					destination_rect.x := (i - 1) * SPRITEW;
					destination_rect.y := (j - 1) * SPRITEH;
					destination_rect.w := SPRITEW;
					destination_rect.h := SPRITEH;
					SDL_BlitSurface(p_sprite_sheet^.bloc, NIL, p_screen, @destination_rect);
				end;
			end;
		
		end;
		
		(*Affichage du personnage*)
		destination_rect.x := p_scene^.i*SPRITEW;
		destination_rect.y := p_scene^.j*SPRITEH;
		destination_rect.w := SPRITEW;
		destination_rect.h := SPRITEH;
		
		(*Choix de la texture à charger en fonction du personnage et de son orientation*)
		case p_scene^.orientation of 
		   droite :	if (perso = 'batman') then player_sprite := p_sprite_sheet^.right_batman 
					else if (perso = 'kirby') then player_sprite := p_sprite_sheet^.right_kirby 
					else if (perso = 'flash') then player_sprite := p_sprite_sheet^.right_flash 
					else if (perso = 'hulk') and (viesDeHulk = 1) then player_sprite := p_sprite_sheet^.right_hulk 
					else player_sprite := p_sprite_sheet^.right_hulk_almost_dead;
					
		   gauche : if (perso = 'batman') then player_sprite := p_sprite_sheet^.left_batman 
					else if (perso = 'kirby') then player_sprite := p_sprite_sheet^.left_kirby 
					else if (perso = 'flash') then player_sprite := p_sprite_sheet^.left_flash 
					else if (perso ='hulk') and (viesDeHulk=1) then player_sprite := p_sprite_sheet^.left_hulk 
					else player_sprite := p_sprite_sheet^.left_hulk_almost_dead ;
		end;
		
		SDL_BlitSurface(player_sprite, NIL, p_screen, @destination_rect);
	end;
end.
