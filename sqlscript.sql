------------------------------------ SCHEMA CREATION ------------------------------------
--
-- CREATE TABLE pais(
--   	id_pais SERIAL NOT NULL PRIMARY KEY,
--   	pais TEXT NOT NULL
-- );
--
-- CREATE TABLE provincia(
--   	provincia INT NOT NULL PRIMARY KEY ,
--   	id_pais INT NOT NULL,
--   	FOREIGN KEY (id_pais) REFERENCES pais ON DELETE RESTRICT
-- );
--
-- CREATE TABLE departamento(
--   	id_departamento SERIAL NOT NULL PRIMARY KEY,
--   	departamento TEXT NOT NULL,
--   	provincia INT NOT NULL,
--   	FOREIGN KEY (provincia) REFERENCES provincia ON DELETE RESTRICT
-- );
--
-- CREATE TABLE localidad (
--   	id_localidad SERIAL NOT NULL PRIMARY KEY,
--   	nombre TEXT NOT NULL,
--   	canthab INT,
--   	id_departamento INT NOT NULL,
--   	FOREIGN KEY (id_departamento) REFERENCES departamento ON DELETE RESTRICT
--  );
--
-- ------------------------------------------- PSM/TRIGGERS -------------------------------------------

CREATE OR REPLACE FUNCTION insert_csv_row() RETURNS trigger AS $$
DECLARE
	pais_id int;
    departamento_id int;
BEGIN
	IF NOT EXISTS(SELECT * FROM pais WHERE pais.pais=NEW.pais) THEN
		INSERT into pais (pais) VALUES(New.pais);
    END IF;

    IF NOT EXISTS(SELECT * FROM provincia WHERE provincia.provincia=NEW.provincia) THEN
        SELECT id_pais FROM pais WHERE pais.pais=New.pais INTO pais_id;
        INSERT into provincia(provincia,id_pais) VALUES(NEW.provincia,pais_id);
    END IF;

    IF NOT EXISTS(SELECT * FROM departamento WHERE departamento.departamento=NEW.departamento and departamento.provincia=New.provincia) THEN
        INSERT into departamento(departamento,provincia) VALUES(New.departamento,NEW.provincia);
    End IF;

    SELECT id_departamento FROM departamento WHERE (departamento.departamento=New.departamento AND departamento.provincia=New.provincia)INTO departamento_id;
    IF NOT EXISTS(SELECT * FROM localidad WHERE localidad.nombre=NEW.nombre and localidad.id_departamento=departamento_id) THEN
    	 INSERT INTO localidad (nombre,canthab,id_departamento) VALUES(New.nombre,new.canthab,departamento_id);
    ELSE
    	RAISE 'localidad with that name already exists';
    End IF;


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_psm() RETURNS trigger AS $$
DECLARE
  pais_id int;
  departamento_id int;
BEGIN

  SELECT id_departamento FROM departamento WHERE (departamento.departamento=old.departamento AND departamento.provincia=old.provincia)INTO departamento_id;
  delete from localidad where id_departamento = departamento_id;
  IF NOT EXISTS(SELECT * FROM aux WHERE  departamento= old.departamento) THEN
    delete from departamento where id_departamento = departamento_id ;
  END IF;
    
   
    RETURN null;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER delete_handler after delete ON aux
FOR EACH ROW 
EXECUTE PROCEDURE delete_psm();


------------------------------------------- DATA IMPORT -------------------------------------------

CREATE VIEW csv_view AS(
    SELECT localidad.nombre,
           pais.pais,
           provincia.provincia,
           departamento.departamento,
           localidad.canthab
    FROM pais
             NATURAL JOIN provincia
             NATURAL JOIN departamento
             NATURAL JOIN localidad
);

CREATE TRIGGER insert_csv_row INSTEAD OF INSERT ON csv_view
FOR EACH ROW EXECUTE PROCEDURE insert_csv_row();

COPY csv_view FROM 'C:\Users\matig\Desktop\localidades.csv' (FORMAT CSV, HEADER);




