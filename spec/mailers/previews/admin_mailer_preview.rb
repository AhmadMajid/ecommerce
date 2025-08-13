class AdminMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/admin_mailer/reply_to_contact_message
  def reply_to_contact_message
    contact_message = ContactMessage.first || ContactMessage.new(
      name: 'John Doe',
      email: 'john@example.com',
      subject: 'Product Inquiry about Winter Collection',
      message: 'I am interested in your winter collection. Could you please provide more information about sizing, materials, and pricing? I am particularly interested in the wool coats and winter boots.',
      created_at: 2.days.ago
    )

    reply_content = "Thank you for your inquiry about our winter collection!\n\nWe're excited to help you find the perfect pieces for the season. Our winter collection features:\n\n• Premium wool coats in sizes XS-XXL\n• Waterproof winter boots with thermal lining\n• Cashmere scarves and gloves\n• Down-filled jackets for extreme weather\n\nAll items are made with sustainable materials and come with our satisfaction guarantee. I'd be happy to schedule a personal styling session to help you choose the best items for your needs.\n\nPlease let me know your preferred size range and any specific requirements, and I'll send you a curated selection with detailed information and pricing.\n\nBest regards,\nSarah Wilson\nCustomer Experience Team"

    AdminMailer.reply_to_contact_message(contact_message, reply_content, 'sarah@yourstore.com')
  end

  # Preview a short reply
  def reply_to_contact_message_short
    contact_message = ContactMessage.first || ContactMessage.new(
      name: 'Jane Smith',
      email: 'jane@example.com',
      subject: 'Quick Question',
      message: 'What are your store hours?',
      created_at: 1.hour.ago
    )

    reply_content = "Hi Jane!\n\nOur store hours are:\nMonday-Friday: 9am-8pm\nSaturday: 10am-6pm\nSunday: 12pm-5pm\n\nThanks for asking!"

    AdminMailer.reply_to_contact_message(contact_message, reply_content)
  end

  # Preview with special characters and formatting
  def reply_to_contact_message_formatted
    contact_message = ContactMessage.first || ContactMessage.new(
      name: 'María García',
      email: 'maria@example.com',
      subject: 'Pregunta sobre envíos internacionales',
      message: 'Hola, ¿realizan envíos a España? Me interesa el producto #12345.',
      created_at: 3.hours.ago
    )

    reply_content = "¡Hola María!\n\nSí, realizamos envíos internacionales a España. Los detalles son:\n\n📦 Tiempo de entrega: 5-7 días laborables\n💶 Costo de envío: €15 para pedidos bajo €100\n🆓 Envío gratuito para pedidos sobre €100\n📋 Se requiere documentación aduanera\n\n¿Te gustaría que procedamos con tu pedido?\n\n¡Saludos!\nEquipo de Atención al Cliente"

    AdminMailer.reply_to_contact_message(contact_message, reply_content, 'soporte@yourstore.com')
  end
end
