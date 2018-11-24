program bloc;
{$linklib SDLmain}
uses sdl, sdl_image, sdl_ttf, keyboard, crt, Interfacebloc_sdl, Media_sdl, sysutils, SDL_MIXER;


procedure alerterNouveauBloc(var tableau_jeu : Scenejeu);
{Affiche une image d’alerte(3) à l’emplacement où chaque nouveau bloc(1) apparaîtra}
var i, nombre_alertes, coordx : Integer;
begin
	nombre_alertes := random(7) + 1;
	i := 0;
	
	(*Ajoute un nombre aléatoire d'alertes(3) à des positions aléatoires de la première ligne du tableau si les conditions sont respectées*)
	while i < nombre_alertes do
	begin
		coordx := random(PLAYGROUNDW) + 1;
		if (tableau_jeu[coordx][1] <> 3) and (tableau_jeu[coordx][i] <> 1) and (tableau_jeu[coordx][2] <> 1) and (tableau_jeu[coordx][PLAYGROUNDH - 7] <> 1) then
			tableau_jeu[coordx][1] := 3;	
		i := i + 1;
	end;
end;


procedure remplacerAlertesParBlocs(var tableau_jeu : Scenejeu);
{Cette procédure permet de générer les blocs en remplaçant les alertes par des blocs (ce qui correspond à mettre un 1(bloc) au lieu d'un 3(alerte) dans le tableau) }
var i : Integer;
begin
	for i := PLAYGROUNDW downto 1 do
		if tableau_jeu[i][1] = 3 then 
			tableau_jeu[i][1] := 1;
end;


procedure deplacerBlocs(var tableau_jeu : Scenejeu; perso : String; var viesDeHulk : Integer; var mort : boolean);
{Déplace les blocs(1) d'une case vers le bas s'il n'y a pas un bloc sur la case du dessous. Fin de partie si le personnage(2) se trouvait dessous à ce moment là.}
var i, j : Integer;
begin
	(*Lecture du tableau de bas en haut et de droite à gauche*)
	for i := PLAYGROUNDW downto 1 do
	begin
		(*-1 car au niveau de la dernière ligne les blocs ne peuvent plus descendre*)
		for j := PLAYGROUNDH - 1 downto 1 do 
		begin
			(*Si la case du dessous est vide(0), le bloc(1) est déplacé d'une case vers le bas*)
			if (tableau_jeu[i][j] = 1) and (tableau_jeu[i][j+1] = 0) then 
			begin
				tableau_jeu[i][j+1] := 1;
				tableau_jeu[i][j] := 0;
			end
			(*Si en dessous du bloc(1) se trouve le personnage(2), il meurt sauf s'il s'agit de hulk auquel cas on lui retire une vie et on supprime le bloc*)
			else if ((tableau_jeu[i][j] = 1) and (tableau_jeu[i][j+1] = 2)) then
			begin
				if (viesDeHulk = 1) and (perso = 'hulk') then
				begin
					tableau_jeu[i][j] := 0; 
					tableau_jeu[i][j+1] := 2;
					viesDeHulk := viesDeHulk - 1;
				end
				else mort := true;
			end;
		end;	
	end;
end;


procedure verifierVideSousPerso(p_scene : PScene; var tableau_jeu : Scenejeu);
{Sert à vérifier si sous le personnage il n'y a rien: si c'est le cas, on fait descendre le personnage jusqu'à ce qu'il y ait un bloc sous lui. 
*Ici il faut noter que les coordonnées qui sont transmises par p_scene ne correspondaient pas à la place réel du personnage dans le jeu: il
*a fallu ajouter 1 aux coordonnées x et y pour placer le personnage correctement dans le tableau et ainsi pouvoir le faire interagir avec les blocs.}
begin
	(*Si rien(0) ne se trouve en dessous du personnage, la position initiale du personnage est supprimée *)
	if (tableau_jeu[p_scene^.i+1][p_scene^.j+2] = 0) then 
	begin
		tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 0;
		(*La position du personnage descend dans le tableau jusqu'à ce que l'on trouve un bloc(1) ou le sol en dessous du personnage: *)
		repeat
			p_scene^.j := p_scene^.j+1;
		until tableau_jeu[p_scene^.i+1][p_scene^.j+2] = 1;
		tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 2; 
	end;
end;


procedure effacerDerniereLigne(var tableau_jeu : Scenejeu; p_scene : PScene);
{Efface la dernière ligne du tableau lorsque celle-ci a toutes les cases remplies de blocs(1)}
var i, nbBlocsParLigne : Integer;
begin
	nbBlocsParLigne := 0;
	
	(* Parcourt la dernière ligne du tableau et compte le nombre de blocs(1) présent sur cette ligne*)
	for i := 1 to PLAYGROUNDW do
	begin
		if tableau_jeu[i][PLAYGROUNDH] = 1 then 
			nbBlocsParLigne := nbBlocsParLigne + 1; 
	end;
	
	(*Si le nombre de blocs présent remplis complètement la ligne, on efface la ligne et on vérifie s'il n'y a pas une case vide sous le personnage*)
	if nbBlocsParLigne = PLAYGROUNDW then 
	begin
		for i := PLAYGROUNDW downto 1 do
			tableau_jeu[i][PLAYGROUNDH] := 0;
		verifierVideSousPerso(p_scene, tableau_jeu);
	end;
end;


procedure lireEvenementClavier(key : TSDL_KeyboardEvent; p_scene : PScene; perso : string; var tableau_jeu : Scenejeu);
{Récupère les touches du clavier sur lesquelles le joueur appuie et déplace le personnage vers la gauche ou la droite en conséquence}
begin
    case key.keysym.sym of
		(*Lorsque le joueur appuie sur la flèche gauche du clavier*)
        SDLK_LEFT : begin
						p_scene^.orientation := gauche; 
						
						(*Si le perso n'est pas contre le mur gauche, qu'il n'a pas de bloc à sa gauche et si rien ne se trouve sous la case à gauche alors 
						* il se déplace à gauche et tombe*)
                        if (p_scene^.i > 0) and (tableau_jeu[p_scene^.i][p_scene^.j+2] = 0) and (tableau_jeu[p_scene^.i][p_scene^.j+1] <> 1)then
						begin
							tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 0;
							p_scene^.i := p_scene^.i-1; 
							
							(*Si le perso est batman alors il ne tombe que d'une seule case vers le bas*)
							if (perso = 'batman') then p_scene^.j := p_scene^.j+1 
							(*Sinon il tombe jusqu'à ce qu'il rencontre un bloc ou le sol*)
							else if (perso = 'kirby') or (perso = 'flash') or (perso = 'hulk') then
							begin
								repeat p_scene^.j := p_scene^.j+1; 
								until tableau_jeu[p_scene^.i+1][p_scene^.j+2] = 1;
							end;
							
							tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 2;
						end
						(*Sinon, si le personnage en se déplaçant à gauche ne tombera pas, et n'est pas gêné, il se déplace juste d'une case à gauche *)
                        else if (p_scene^.i > 0) and (tableau_jeu[p_scene^.i][p_scene^.j+1] <> 1) then
						begin
                            p_scene^.i := p_scene^.i-1; 
                            tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 2; 
                            tableau_jeu[p_scene^.i+2][p_scene^.j+1] := 0; 
                        end
                        (*Si par contre il y a un bloc à sa gauche, le personnage monte d'un cran*)
                        else if (p_scene^.i > 0) and (tableau_jeu[p_scene^.i][p_scene^.j+1] = 1) and (tableau_jeu[p_scene^.i+1][p_scene^.j] <> 1) then
                        begin
							tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 0;
							p_scene^.j := p_scene^.j-1; 
                            tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 2; 
                        end;
                     end;
                     
        (*Fonctionnement similaire lorsque le joueur appuie sur la flèche droite *)     
        SDLK_RIGHT : begin 
                        p_scene^.orientation := droite; (*L'orientation du perso est tourné à droite*)
                        
                        if (p_scene^.i < PLAYGROUNDW-1) and (tableau_jeu[p_scene^.i+2][p_scene^.j+2] = 0) and (tableau_jeu[p_scene^.i+2][p_scene^.j+1] <> 1)then
						begin
							tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 0;
							p_scene^.i := p_scene^.i+1;
							
							if (perso = 'batman') then
								p_scene^.j := p_scene^.j+1
							else if (perso = 'kirby') or (perso = 'flash') or (perso = 'hulk') then
							begin
								repeat p_scene^.j := p_scene^.j+1;	
								until tableau_jeu[p_scene^.i+1][p_scene^.j+2] = 1;
							end;
							
							tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 2;
						end
                        else if (p_scene^.i < PLAYGROUNDW-1) and (tableau_jeu[p_scene^.i+2][p_scene^.j+1] <> 1) then
                        begin
                            p_scene^.i := p_scene^.i+1;
                            tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 2;
                            tableau_jeu[p_scene^.i][p_scene^.j+1] := 0;
                        end
                        else if (p_scene^.i < PLAYGROUNDW-1) and (tableau_jeu[p_scene^.i+2][p_scene^.j+1] = 1) and (tableau_jeu[p_scene^.i+1][p_scene^.j] <> 1) then
                        begin
							tableau_jeu[p_scene^.i+1][p_scene^.j+1] := 0;
							p_scene^.j := p_scene^.j-1;
                            tableau_jeu[p_scene^.i+1][p_scene^.j+1]:= 2;
                        end;
                     end;
    end;
end;


procedure choisirPersonnage(var p_screen : PSDL_SURFACE; p_sprite_sheet : PSpriteSheet; key : TSDL_KeyboardEvent; var choisi_personnage : Boolean; var perso : string; var i : Integer);
{Permet au joueur de choisir son personnage à l'aide du clavier}
var tab : array[1..4] of string;
	destination_rect : TSDL_RECT;
	px, py : Integer;
begin
    tab[1] := 'kirby'; 
    tab[2] := 'hulk';
    tab[3] := 'flash';
    tab[4] := 'batman';
    
    case key.keysym.sym of
		(*En appuyant sur la flèche de gauche, un personnage différent est sélectionné*)
        SDLK_LEFT : begin 
                        if (i > 1) and (i < 5) then
							i := i - 1
						else if i = 1 then
							i := 4; (*Puisque il est impossible d'aller à tab[negatif], n est réinitialisé à 4*) 
                    end;
        
        (*Même principe ici en appuyant sur la flèche de droite mais en sens inverse *)
        SDLK_RIGHT : begin 
                        if (i > 0) and (i < 4) then
							i := i + 1
						else if i = 4 then
							i := 1; 
                     end;
        
        (*En appuyant sur touche backspace, on valide notre choix et on rentre dans la partie*)
        SDLK_BACKSPACE : begin
							perso := tab[i];
							choisi_personnage := True;
						 end;
    end;
    
    (* Indique la position à prendre pour le carré de sélection afin qu'il s'affiche autour du personnage choisi*)
    case i of
		1 : begin px := 175; py := 285; end;
		2 : begin px := 300; py := 666; end;
		3 : begin px := 600; py := 340; end;
		4 : begin px := 338; py := 108; end;
	end;
	
	destination_rect.x := px;
	destination_rect.y := py;
	destination_rect.w := SPRITEW;
	destination_rect.h := SPRITEH;
	SDL_BlitSurface(p_sprite_sheet^.carre_selection_perso, NIL, p_screen, @destination_rect);
	SDL_Flip(p_screen);
end;


procedure afficherRecords(nom : string; var best_kirby_joueur, best_hulk_joueur, best_batman_joueur, best_flash_joueur : String; var score_kirby, score_batman, score_flash, score_hulk, best_kirby_score, best_batman_score, best_flash_score, best_hulk_score : LongInt; p_screen : PSDL_SURFACE);
{Affiche les records pour chaque personnage}
begin
	(*Si le score réalisé est supérieur au record alors on met à jour le record(nom + score) et on l'affiche à l'écran
	* Sinon, on affiche le pseudo et le score du joueur détenant le record *)
	if (score_kirby > best_kirby_score) then
	begin
		best_kirby_joueur := nom;
		best_kirby_score := score_kirby;
		ecrire(p_screen, 'Nouveau record de ' + nom + ': ' + IntToStr(best_kirby_score), 50, 220, 28);
	end
	else ecrire(p_screen, best_kirby_joueur + ': ' + IntToStr(best_kirby_score), 70, 220, 28);

	if (score_batman > best_batman_score) then
	begin
		best_batman_joueur := nom;
		best_batman_score := score_batman;
		ecrire(p_screen, 'Nouveau record de ' + nom + ': ' + IntToStr(best_batman_score), 213, 43, 28);
	end
	else ecrire(p_screen, best_batman_joueur + ': ' + IntToStr(best_batman_score), 233, 43, 28);
	
	if (score_flash > best_flash_score) then
	begin
		best_flash_joueur := nom;
		best_flash_score := score_flash;
		ecrire(p_screen, 'Nouveau record de ' + nom + ': ' + IntToStr(best_flash_score), 475, 275, 28);
	end
	else ecrire(p_screen, best_flash_joueur + ': ' + IntToStr(best_flash_score), 495, 275, 28);
	
	if (score_hulk > best_hulk_score) then
	begin
		best_hulk_joueur := nom;
		best_hulk_score := score_hulk;
		ecrire(p_screen, 'Nouveau record de ' + nom + ': ' + IntToStr(best_hulk_score), 175, 601, 28);
	end
	else ecrire(p_screen, best_hulk_joueur + ': ' + IntToStr(best_hulk_score), 195, 601, 28);
	
	(*On écrit les scores du joueur*)
	ecrire(p_screen, 'Ton score: ' + IntToStr(score_kirby), 70, 250, 28);
	ecrire(p_screen, 'Ton score: ' + IntToStr(score_batman), 233, 73, 28);
	ecrire(p_screen, 'Ton score: ' + IntToStr(score_flash), 495, 305, 28);
	ecrire(p_screen, 'Ton score: ' + IntToStr(score_hulk), 195, 631, 28);
end;


procedure lireEvenementSouris(mouseEvent : TSDL_MouseButtonEvent; var choisi_personnage : Boolean; var perso : string);
{Sélection d'un personnage avec la souris et lancement du jeu}
var x, y : LongInt ;
begin
	(*Récupération des coordonnées de la souris*)
	SDL_GetMouseState(x, y);

	(*Selon où le joueur clique avec sa souris, un personnage différent est sélectionné*)
	if (x > 175) and (x < 239) and (y > 285) and (y < 349) then
		begin
			choisi_personnage := True;
			perso := 'kirby';	
		end
	else if (x > 338) and (x < 402) and (y > 108) and (y < 172) then
		begin
			choisi_personnage := True;
			perso := 'batman';
		end
	else if (x > 300) and (x < 364) and (y > 666) and (y < 730) then
		begin
			choisi_personnage := True;
			perso := 'hulk';
		end
	else if (x > 600) and (x < 664) and (y > 340) and (y < 404) then
		begin
			choisi_personnage := True;
			perso := 'flash';
		end	
	else choisi_personnage := False;
end;


procedure initialiser(var tableau_jeu : Scenejeu);
{Cette procédure toute simple sert à créer une ligne de blocs invisibles, qui correspond
au sol, pour s'assurer que tout bloc qui tombe doit automatiquement s'arrêter une fois arrivé 
à celui-ci. Elle permet également d'initialiser le tableau en le remplissant de 0(vide)}
var i, j : Integer;
begin
	for i := 1 to PLAYGROUNDW + 1 do 
	begin
		for j := 1 to PLAYGROUNDH + 1 do
			tableau_jeu[i][j] := 0; 
		tableau_jeu[i][PLAYGROUNDH + 1] := 1;
	end;
end;


var choisi_personnage, not_click, partie_en_cours, mort : boolean;
	nombre_joueurs, i, vitesse_bloc, k, vitesse_perso, viesDeHulk : Integer;
	perso, nom, best_kirby_joueur, best_hulk_joueur, best_batman_joueur, best_flash_joueur, msg : string;
	j, score_kirby, score_batman, score_flash, score_hulk, score, best_kirby_score, best_batman_score, best_flash_score, best_hulk_score, best : LongInt;
	tableau : Scenejeu;
	joueurs : Tab_joueurs;
	fichier : file of Tab_joueurs;
	destination_rect : TSDL_RECT;
	p_screen : PSDL_Surface; (*Pointeur vers une "surface" qui sera affichée*)
	p_scene : PScene; (*Pointeur vers une scène de jeu*)
	p_sprite_sheet : PSpriteSheet; (*Pointeur vers une feuille de textures*)
	event : TSDL_Event; (*Un événement*)
  
begin
	Clrscr;
	best_hulk_joueur := ' ';
	best_flash_joueur := ' ';
	best_batman_joueur := ' ';
	best_kirby_joueur := ' ';
	best_flash_score := 0; 
	best_kirby_score := 0;
	best_batman_score := 0;
	best_hulk_score := 0;
	nombre_joueurs := 0;
	
	assign(fichier,'listeDesScores'); 
	reset(fichier);

	(*Lecture du fichier ouvert ci-dessus afin de récupérer les noms et scores des joueurs détenant les records*)
	while not (eof(fichier)) do
		begin
			read(fichier, joueurs);
			
			if joueurs[nombre_joueurs].best_kirby_score > best_kirby_score then
				begin		
				best_kirby_score := joueurs[nombre_joueurs].best_kirby_score;
				best_kirby_joueur := joueurs[nombre_joueurs].nom;
				end;
				
			if joueurs[nombre_joueurs].best_flash_score > best_flash_score then
				begin
				best_flash_score := joueurs[nombre_joueurs].best_flash_score;
				best_flash_joueur := joueurs[nombre_joueurs].nom;
				end;
				
			if joueurs[nombre_joueurs].best_hulk_score > best_hulk_score then
				begin
				best_hulk_score := joueurs[nombre_joueurs].best_hulk_score;
				best_hulk_joueur := joueurs[nombre_joueurs].nom;
				end;
				
			if joueurs[nombre_joueurs].best_batman_score > best_batman_score then
				begin
				best_batman_score := joueurs[nombre_joueurs].best_batman_score;
				best_batman_joueur := joueurs[nombre_joueurs].nom;
				end;
				
			nombre_joueurs := nombre_joueurs + 1;
		end;

	close(fichier);
	
	write('Veuillez entrer votre pseudo: ');
	read(nom);
	
	(*Initialisation de la SDL*)
	SDL_Init(SDL_INIT_VIDEO);
	SDL_Init(SDL_INIT_AUDIO);
	(*Création d'une surface "écran" puis d'une feuille de texture*)
	p_screen := SDL_SetVideoMode(SURFACEWIDTH, SURFACEHEIGHT, 32, SDL_SWSURFACE);
	p_sprite_sheet := newSpriteSheet();
	SDL_EnableKeyRepeat(10, 500);
	
	score := 0;
	best := 0;
	score_kirby := 0;
	score_batman := 0;
	score_flash := 0;
	score_hulk := 0;
	
	partie_en_cours := true;
	mort := false;
	
	(*Boucle principale*)
	while partie_en_cours do
	begin
		i := 1;
		j := 0;
		mort := false; (* On réinitialise cette variable à chaque fois qu'on retourne au menu*)
		p_scene := newScene();
		choisi_personnage := False;
		afficherEcranMenu(p_screen, p_sprite_sheet, mort, score);
		afficherRecords(nom, best_kirby_joueur, best_hulk_joueur, best_batman_joueur, best_flash_joueur, score_kirby, score_batman, score_flash, score_hulk, best_kirby_score, best_batman_score, best_flash_score, best_hulk_score, p_screen);
		SDL_Flip(p_screen);
		
		(*Boucle correspondant au menu où le joueur chosit son personnage*)
		while not choisi_personnage do
		begin
			(*On lit un evenement(clic de la souris ou enfoncement d'une touche du clavier) et on agit en consequence*)
			SDL_PollEvent(@event);
			if event.type_ = SDL_MOUSEBUTTONDOWN then
			   lireEvenementSouris(event.button, choisi_personnage, perso)
			else if (event.type_ = SDL_KEYDOWN) and(j > 400000) then
			begin
				afficherEcranMenu(p_screen, p_sprite_sheet, mort, score);
				afficherRecords(nom, best_kirby_joueur, best_hulk_joueur, best_batman_joueur, best_flash_joueur, score_kirby, score_batman, score_flash, score_hulk, best_kirby_score, best_batman_score, best_flash_score, best_hulk_score, p_screen);
				choisirPersonnage(p_screen, p_sprite_sheet, event.key, choisi_personnage, perso, i);
				j := 0;
			end;
			
			(*Si le joueur clique sur la croix, on sort de chaque boucle et on ferme le programme*)
			if event.type_ = SDL_QUITEV then
			begin
				choisi_personnage := True; 
				partie_en_cours := false;
				mort := true;
			end;
			
			j := j + 1;
		end;	
		
		(*Boucle vérifiant que le joueur n'a pas clique sur la croix pour fermer le jeu*)
		if partie_en_cours then
		begin
			randomize();
			
			(*Chaque personnage a une vitesse de déplacement qui lui est propre. Le record du personnage sélectionné est enregistré.*)
			if (perso = 'kirby') then
			begin
				vitesse_perso := 10;
				best := best_kirby_score;
			end
			else if(perso = 'batman') then
			begin
				vitesse_perso := 10;
				best := best_batman_score;
			end
			else if (perso = 'flash') then 
			begin
				vitesse_perso := 3;
				best := best_flash_score;
			end
			else if (perso = 'hulk') then
			begin
				vitesse_perso := 14;
				best := best_hulk_score;
			end; 
			     
			i := 0;
			j := 0;
			k := 0;
			vitesse_bloc := 11;
			score := 0;
			viesDeHulk := 1;
			initialiser(tableau);
			lancerMusique('musiqueDeJeu.mp3');
			tableau[p_scene^.i+1][p_scene^.j+1] := 2;(*Le personnage est placé au sol, au milieu du terrain*)
			
			(*Boucle de partie*)
			while not mort do
			begin
			
				(*A intervalles de temps réguliers, les alertes apparaissent puis sont remplacées par des blocs*)
				if i = 70 then 
					alerterNouveauBloc(tableau) 
				else if i = 140 then 
				begin
					remplacerAlertesParBlocs(tableau);
					i := 0;
				end;
				
				(*Les blocs se déplacent d'une case vers le bas à chaque fois que la condition est validée.*)
				if k = vitesse_bloc then
				begin
					deplacerBlocs(tableau, perso, viesDeHulk, mort);
					k := 0;
				end;
			
				i := i + 1;
				k := k + 1;
				
				(*A chaque fois que le score est égal à un multiple de 300, la vitesse de descente des blocs augmente*)
				if ((score mod 300) = 0) and (vitesse_bloc > 1) then 
				begin
					vitesse_bloc := vitesse_bloc - 1; 
					k := 0;
				end;

				effacerDerniereLigne(tableau, p_scene);
				j := j + 1;
				score := score + 1;
		
				(*Affichage des éléments graphiques*)
				destination_rect.x := 0;
				destination_rect.y := 0;
				destination_rect.w := SURFACEWIDTH;
				destination_rect.h := SURFACEHEIGHT;
				SDL_BlitSurface(p_sprite_sheet^.screen, NIL, p_screen, @destination_rect);
				ecrire(p_screen,IntToStr(score), 340, 160, 58);
				ecrire(p_screen, 'Best: ' + IntToStr(best), 340, 250, 28);
				afficherAlertesBlocsPerso(p_screen, p_sprite_sheet, p_scene, perso, viesDeHulk, tableau);
				SDL_Flip(p_screen);
				
				SDL_PollEvent(@event);
				
				(*Boucle permettant de contrôler la vitesse de déplacement du personnage*)
				if j > vitesse_perso then
				begin
					if event.type_ = SDL_KEYDOWN then 
					begin
						lireEvenementClavier(event.key, p_scene, perso, tableau); 
						j := 0; (*On reset la variable d'incrémentation, pour laisser passer un certain temps avant qu'il puisse bouger de nouveau*)
					end
					else if event.type_ = SDL_KEYUP then 
					(*Si le joueur n'appuie sur aucune touche, la fonction vide est appelée, pour faire descendre le personnage si besoin*)
						verifierVideSousPerso(p_scene, tableau); 
				end;
			
				(*Tant qu'on ne ferme pas la fenêtre on continue la boucle*)
				if event.type_ = SDL_QUITEV then
				begin
					mort := true;
					partie_en_cours := false;
				end;
			end;
		  
			(*Selon le personnage sélectionné auparavant, le score actuel du joueur est retranscrit dans le score correct*)
			if (perso = 'kirby') then score_kirby := score
			else if(perso = 'batman') then score_batman := score
			else if (perso = 'flash') then  score_flash := score
			else if (perso = 'hulk') then score_hulk := score;
		  
			(*Boucle de fin de partie, affichant l'écran Game Over et lançant la musique définie*)
			if ((mort = true) and (partie_en_cours = true)) then
			begin
				lancerMusique('musiqueGameOver.mp3');
				afficherEcranGameOver(p_screen, p_sprite_sheet, score);
				ecrire(p_screen, IntToStr(score), 350, 300, 48);

				(*Selon le score obtenu, un message est affiché au joueur*)
				case score of
					0..1000 : msg := 'You have the skill set of a 5 year old';
					1001..2000 : msg := 'Go home, baby';
					2001..15000 : msg := 'I hope you will do better one day...';
					15001..32000 : msg := 'You''ve become addicted';
				end;

				ecrire(p_screen, msg, 265, 368, 28);
				SDL_Flip(p_screen);
				
				not_click := true;
				
				(*Tant que le joueur n'appuie pas sur la touche espace ou ne clique pas avec la souris, on reste sur l'écran Game Over*)
				while not_click do 
				begin
					SDL_PollEvent(@event);
					
					if (event.key.keysym.sym = SDLK_SPACE) or (event.type_ = SDL_MOUSEBUTTONDOWN) then not_click := false;
					
					if event.type_ = SDL_QUITEV then
					begin
						not_click := false;
						partie_en_cours := false;
					end;
				end;
			end;
		end;
	end;

	(*Ouvre le fichier des scores et y inscrit le nom du joueur ainsi que ses records*)
	assign(fichier, 'listeDesScores');
	reset(fichier);
	
	while not(eof(fichier)) do read(fichier, joueurs);
	
	joueurs[nombre_joueurs].nom := nom;
	joueurs[nombre_joueurs].best_kirby_score := best_kirby_score;
	joueurs[nombre_joueurs].best_batman_score := best_batman_score;
	joueurs[nombre_joueurs].best_flash_score := best_flash_score;
	joueurs[nombre_joueurs].best_hulk_score := best_hulk_score;

	write(fichier, joueurs);
	close(fichier);
	
	(*On libère la scène et la feuille de texture*)
	libererMemoire(p_scene, p_sprite_sheet);
	(*On libère la surface liée à l'écran*)
	SDL_FreeSurface(p_screen);
	(*On décharge les bibliotheques*)
	Mix_CloseAudio();
	(*On libere SDL*)
	SDL_Quit();
end.
