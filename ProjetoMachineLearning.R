#Instalar pacotes necessários
install.packages("Amelia")
install.packages("randomForest")
install.packages("ggplot2")

#Chamar os pacotes necessários
library(randomForest)
library(ggplot2)
library(Amelia)

#Importar os dados
train_set_view = read.csv("train.csv", na.strings = "")
test_set_view = read.csv("test.csv", na.strings = "")
train_set <- read.csv("train.csv", stringsAsFactors=T) 
test_set  <- read.csv("test.csv",  stringsAsFactors=T)

#Verificação e tratamento dos dados

##Check dados faltantes - Valores faltando em Cabin, Age e Fare
missmap(train_set_view, col=c("black", "grey"))
missmap(test_set_view, col=c("black", "grey"))

##Pessoas sobreviventes e pessoas que morreram
ggplot(train_set_view, aes(x = Survived)) +
  geom_bar(width=0.5, fill = "coral") +
  geom_text(stat='count', aes(label=stat(count)), vjust=-0.5) +
  theme_classic()

##Podemos inferir que um número muito menor de pessoas sobreviveu e, nessas, 
##maior número de mulheres do que de homens.
ggplot(train_set_view, aes(x = Survived, fill=Sex)) +
  geom_bar(position = position_dodge()) +
  geom_text(stat='count', 
            aes(label=stat(count)), 
            position = position_dodge(width=1), vjust=-0.5)+
  theme_classic()

##Podemos inferir que as chances de sobrevivência dos passageiros da 
##1ª classe foram maiores do que as demais.
train_set_view$Pclass = factor(train_set_view$Pclass, order=TRUE, levels = c(3, 2, 1))
ggplot(train_set_view, aes(x = Survived, fill=Pclass)) +
  geom_bar(position = position_dodge()) +
  geom_text(stat='count', 
            aes(label=stat(count)), 
            position = position_dodge(width=1), 
            vjust=-0.5)+theme_classic()

##Checando se há dados faltantes (variáveis ou amostras) descritiva dos 
##conjuntos
summary(train_set)
summary(test_set)

##Método alternativo para checar dados faltantes alternativamente
colSums(is.na(train_set)) 
colSums(is.na(test_set))
colSums(train_set =="")
colSums(test_set =="")

##Criar coluna faltante preenchida com NA no test_set. Originalmente não 
##há variável Survived emtest_set, pois são os os dados de teste.
test_set$Survived <- NA

##Criando uma coluna para identificar se o dado é treino ou teste e 
##Agrupando os datasets
train_set$IsTrainSet <-T
test_set$IsTrainSet  <-F
titanic_set <- rbind(train_set, test_set)

##Checando se há dados faltantes (variáveis ou amostras) descritiva do 
##conjunto titanic_set
summary(titanic_set)

##Forma alternativa de checar dados faltantes
colSums(is.na(titanic_set)) 
colSums(titanic_set =="", na.rm = TRUE)

##Transformações simples (corrigindo dados, NA num pela mediana e NA em factor
##pela moda)
titanic_set$Survived                         <- as.factor(titanic_set$Survived)
titanic_set$Pclass                           <- as.factor(titanic_set$Pclass)
titanic_set$Age[is.na(titanic_set$Age)]      <- median(titanic_set$Age, na.rm = T)
titanic_set$SibSp                            <- as.numeric(titanic_set$SibSp)
titanic_set$Parch                            <- as.numeric(titanic_set$Parch)
titanic_set$Fare[is.na(titanic_set$Fare)]    <- median(titanic_set$Fare, na.rm = T)
titanic_set$Embarked[titanic_set$Embarked==""] <-"S"
titanic_set$Embarked                         <-as.factor(as.character(titanic_set$Embarked))
table(titanic_set$Embarked)

#Construir o modelo
titanic_train <- titanic_set[titanic_set$IsTrainSet==T,]
titanic_test  <- titanic_set[titanic_set$IsTrainSet==F,]

#Criando a formula
survived_formula <- as.formula("Survived ~ Sex + Pclass + Age + SibSp + Parch + Fare + Embarked")

#Criando o modelo
titanic_model <- randomForest(formula = survived_formula,
                              data = titanic_train,
                              ntree = 65,
                              importance = T)

#Interpretando resultados
titanic_model

#Mostrando graficos curva
plot(titanic_model)

#Gerando a matriz de importância das variáveis
importance_var   <- importance(titanic_model, type=1)

importance_var

#Dando uma formatada na tabela
tabela_de_importancia <- data.frame(variaveis=row.names(importance_var), 
                                    importancia=importance_var[,1]);
tabela_de_importancia


#Gerando o grafico
grafico <- ggplot(tabela_de_importancia, 
                  aes(x=reorder(variaveis,importancia), y=importance_var)) +
  geom_bar(stat="identity", fill="#5cc9c1") +
  coord_flip() + 
  theme_light(base_size=20) +
  xlab("") +
  ylab("Importância") + 
  ggtitle("Importância das variáveis no Modelo RF") +
  theme(plot.title=element_text(size=18))
grafico

#Preparando predição e gerando arquivo

##Cria um data frame com o campo PassengerId
submission <- data.frame(PassengerId = test_set$PassengerId,
                         Survived = predict(titanic_model, newdata =  titanic_test))

##Vizualizando os dados de saida
View(submission)

##Criando arquivo
write.csv(submission, file = "titanic_prediction_r.csv", row.names=F)
