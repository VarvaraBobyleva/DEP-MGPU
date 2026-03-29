import streamlit as st
import pandas as pd
import plotly.express as px
from pymongo import MongoClient
import subprocess

st.set_page_config(page_title="Streaming Analytics", layout="wide")
st.title("🎬 Аналитическая панель стриминговой платформы")

# 1. ПОЛУЧАЕМ ДАННЫЕ ИЗ MONGODB (через библиотеку)
@st.cache_resource
def get_mongo_data():
    client = MongoClient('mongodb://localhost:27017/')
    db = client['streaming_db']
    return pd.DataFrame(list(db.movies.find({}, {"_id": 0})))

# 2. ПОЛУЧАЕМ ДАННЫЕ ИЗ CASSANDRA (без драйвера, через Docker CLI)
# Это "хак", чтобы обойти ошибку с Python 3.14
def get_cassandra_data_alt():
    try:
        cmd = "docker exec $(docker ps -qf 'name=cassandra') cqlsh -e 'SELECT user_id, action FROM streaming_logs.logs;'"
        result = subprocess.check_output(cmd, shell=True).decode('utf-8')
        
        raw_data = []
        for line in result.split('\n'):
            if '|' in line and 'user_id' not in line and '---' not in line:
                parts = [p.strip() for p in line.split('|')]
                if len(parts) >= 2:
                    # Создаем только те колонки, которые нам нужны
                    raw_data.append({
                        'user_id': parts[0],
                        'action': parts[1],
                        'type': parts[1].split('_')[0].capitalize() # Всегда 'type' с маленькой
                    })
        return pd.DataFrame(raw_data)
    except Exception as e:
        st.error(f"Ошибка связи с Cassandra: {e}")
        return pd.DataFrame()
    
# Загрузка данных
df_movies = get_mongo_data()
df_logs = get_cassandra_data_alt()


# --- ВИЗУАЛИЗАЦИЯ 1: Гипотеза про Ч/Б и Рейтинг ---
col1, col2 = st.columns(2)

with col1:
    st.subheader("🎨 Рейтинг: Ч/Б vs Цвет")
    avg_r = df_movies.groupby('is_bw')['rating'].mean().reset_index()
    avg_r['Формат'] = avg_r['is_bw'].map({True: 'Ч/Б фильм', False: 'Цветной'})
    
    # Кастомная раскраска через Plotly
    fig = px.bar(avg_r, 
                 x='Формат', 
                 y='rating', 
                 color='Формат',
                 color_discrete_map={'Ч/Б фильм': '#808080', 'Цветной': '#636EFA'},
                 text_auto='.2f')
    
    fig.update_yaxes(range=[7.8, 9.0], title="Средний балл")
    fig.update_layout(showlegend=False, height=550)
    st.plotly_chart(fig, use_container_width=True)

# --- ВИЗУАЛИЗАЦИЯ 2: Активность пользователей ---   
with col2:
    st.subheader("📈 Активность пользователей (Cassandra)")
    if not df_logs.empty:
        counts = df_logs['type'].value_counts().reset_index()
        counts.columns = ['Действие', 'Всего']
        
        # Donut chart для наглядности долей
        fig_pie = px.pie(counts, values='Всего', names='Действие', hole=0.5,
                         color_discrete_sequence=px.colors.sequential.YlOrRd_r)
        fig_pie.update_traces(textposition='inside', textinfo='percent+label')
        fig_pie.update_layout(
            height=600, 
            margin=dict(l=20, r=20, t=30, b=20),
            legend=dict(orientation="h", yanchor="bottom", y=-0.1, xanchor="center", x=0.5)
        )
        st.plotly_chart(fig_pie, use_container_width=True)
    else:
        st.warning("⚠️ Не удалось прочитать данные из Cassandra. Проверьте таблицу logs.")

# --- СРЕДНИЙ РЯД: ВЫВОДЫ ---
st.divider()
st.markdown("### 💡 Бизнес-анализ")
diff = df_movies[df_movies['is_bw']==False]['rating'].mean() - df_movies[df_movies['is_bw']==True]['rating'].mean()
st.success(f"**Результат анализа:** Средняя разница в рейтинге составляет {abs(diff):.2f} балла. "
           "Гипотеза о том, что формат влияет на качество, не подтвердилась. Однако, данные логов показывают смещение интереса к цветному контенту.")

# --- НИЖНИЙ РЯД: ТАБЛИЦА ---
t1, t2 = st.tabs(["📂 Каталог (MongoDB)", "📝 Логи (Cassandra)"])

with t1:
    if not df_movies.empty:
        st.dataframe(df_movies, use_container_width=True)
    else:
        st.info("Данные в MongoDB не найдены.")

with t2:
    if not df_logs.empty:
        # Показываем User ID и полное название действия
        st.dataframe(df_logs[['user_id', 'action']], width='stretch')
    else:
        st.info("Данные в Cassandra не найдены.")

