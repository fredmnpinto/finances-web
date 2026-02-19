import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: String
  }

  connect() {
    const data = JSON.parse(this.dataValue)
    
    new Chart(this.element.querySelector("canvas"), {
      type: 'pie',
      data: {
        labels: data.labels,
        datasets: [{
          data: data.values,
          backgroundColor: [
            '#3b82f6',
            '#10b981',
            '#f59e0b',
            '#ef4444',
            '#8b5cf6',
            '#ec4899',
            '#06b6d4',
            '#84cc16',
            '#f97316',
            '#6366f1'
          ]
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = parseFloat(context.raw)
                const total = context.dataset.data.reduce((a, b) => a + parseFloat(b), 0)
                const percentage = ((value / total) * 100).toFixed(1)
                return `${context.label}: $${value.toFixed(2)} (${percentage}%)`
              }
            }
          }
        }
      }
    })
  }
}
